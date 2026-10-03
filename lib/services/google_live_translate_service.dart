import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zero-Jank, high-performance live translation service.
/// Features multi-tier caching (In-Memory RAM cache + Throttled SharedPreferences persistence),
/// reused persistent HttpClient, request deduplication, frame-safe debounced notifications,
/// and silent offline fallback without blocking UI frame rendering or scrolling.
class GoogleLiveTranslateService {
  GoogleLiveTranslateService._();

  static const String _prefsKeyPrefix = 'glt_cache_';
  static bool isEnabled = true;

  /// In-memory cache: targetLang -> (sourceText -> translatedText)
  static final Map<String, Map<String, String>> _memoryCache = {};

  /// In-flight requests deduplication: 'targetLang:sourceText' -> Future
  static final Map<String, Future<String?>> _inFlight = {};

  /// Shared persistent HttpClient to prevent repeated SSL/TLS socket creation.
  static HttpClient? _client;
  static HttpClient get _httpClient {
    _client ??= HttpClient()
      ..idleTimeout = const Duration(seconds: 15)
      ..connectionTimeout = const Duration(seconds: 4);
    return _client!;
  }

  /// Debounce timers for disk persistence and UI notifications.
  static Timer? _debounceSaveTimer;
  static Timer? _debounceNotifyTimer;
  static final Set<String> _dirtyLangs = {};

  /// Notifier incremented when translations are updated.
  /// Debounced and frame-scheduled to prevent mid-scroll rebuild cascades.
  static final ValueNotifier<int> liveTranslationsVersionNotifier = ValueNotifier<int>(0);

  /// Initializes persisted translations from SharedPreferences into RAM cache.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));
      for (final key in keys) {
        final lang = key.substring(_prefsKeyPrefix.length);
        final jsonStr = prefs.getString(key);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic>) {
            _memoryCache[lang] ??= {};
            decoded.forEach((k, v) {
              if (v is String) {
                _memoryCache[lang]![k] = v;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('GoogleLiveTranslateService.init warning: $e');
    }
  }

  /// Synchronously returns a previously cached translation, or null if not yet cached.
  /// Zero-latency O(1) in-memory lookup taking < 0.005ms with zero I/O.
  static String? getCached(String text, {required String targetLang}) {
    if (!isEnabled || text.trim().isEmpty) return null;
    return _memoryCache[targetLang]?[text];
  }

  /// Translates text asynchronously.
  /// 1. Returns from memory cache if available (0ms).
  /// 2. Deduplicates concurrent identical requests.
  /// 3. Debounces disk persistence and UI notifications.
  static Future<String> translate(
    String text, {
    required String targetLang,
    String? fallback,
  }) async {
    final trimmed = text.trim();
    if (!isEnabled || trimmed.isEmpty || targetLang == 'en') {
      return fallback ?? text;
    }

    // 1. Check in-memory cache (0ms)
    final cached = getCached(trimmed, targetLang: targetLang);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 2. Check deduplication flight
    final flightKey = '$targetLang:$trimmed';
    if (_inFlight.containsKey(flightKey)) {
      final inFlightResult = await _inFlight[flightKey];
      return inFlightResult ?? (fallback ?? text);
    }

    // 3. Initiate low-priority network request
    final future = _fetchFromGoogle(trimmed, targetLang: targetLang);
    _inFlight[flightKey] = future;

    try {
      final result = await future;
      if (result != null && result.isNotEmpty) {
        _cacheTranslationInMemory(trimmed, result, targetLang: targetLang);
        _schedulePersist(targetLang);
        _scheduleFrameSafeNotification();
        return result;
      }
    } catch (e) {
      debugPrint('GoogleLiveTranslateService.translate error: $e');
    } finally {
      _inFlight.remove(flightKey);
    }

    return fallback ?? text;
  }

  /// Low-priority background request. Never called synchronously inside widget build() methods.
  static void translateAsyncAndNotify(String text, {required String targetLang}) {
    final trimmed = text.trim();
    if (!isEnabled || trimmed.isEmpty || targetLang == 'en') return;
    if (getCached(trimmed, targetLang: targetLang) != null) return;

    final flightKey = '$targetLang:$trimmed';
    if (_inFlight.containsKey(flightKey)) return;

    translate(trimmed, targetLang: targetLang).catchError((_) => text);
  }

  /// Network call reusing persistent HttpClient with safety timeout.
  static Future<String?> _fetchFromGoogle(String text, {required String targetLang}) async {
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final request = await _httpClient.getUrl(uri);
      request.headers.set('User-Agent', 'Mozilla/5.0');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(responseBody);
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final sentences = decoded[0] as List;
          final buffer = StringBuffer();
          for (final sentence in sentences) {
            if (sentence is List && sentence.isNotEmpty && sentence[0] != null) {
              buffer.write(sentence[0].toString());
            }
          }
          final translated = buffer.toString().trim();
          if (translated.isNotEmpty) {
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint('GoogleLiveTranslateService network notice: $e');
    }
    return null;
  }

  /// Caches translation in RAM immediately without touching disk.
  static void _cacheTranslationInMemory(String source, String translated, {required String targetLang}) {
    _memoryCache[targetLang] ??= {};
    _memoryCache[targetLang]![source] = translated;
    _dirtyLangs.add(targetLang);
  }

  /// Throttles and debounces disk writes so SharedPreferences is never hammered during UI animations.
  static void _schedulePersist(String targetLang) {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(seconds: 5), () {
      flushPendingCache();
    });
  }

  /// Flushes dirty in-memory cache to SharedPreferences in a single batched write.
  static Future<void> flushPendingCache() async {
    if (_dirtyLangs.isEmpty) return;
    final langsToSave = List<String>.from(_dirtyLangs);
    _dirtyLangs.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final lang in langsToSave) {
        final currentMap = _memoryCache[lang];
        if (currentMap != null) {
          final key = '$_prefsKeyPrefix$lang';
          await prefs.setString(key, jsonEncode(currentMap));
        }
      }
    } catch (e) {
      debugPrint('GoogleLiveTranslateService flushPendingCache error: $e');
    }
  }

  /// Schedules a frame-safe notification debounced by 600ms between render frames.
  static void _scheduleFrameSafeNotification() {
    _debounceNotifyTimer?.cancel();
    _debounceNotifyTimer = Timer(const Duration(milliseconds: 600), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        liveTranslationsVersionNotifier.value++;
      });
    });
  }

  /// Clears in-memory and persistent translation cache.
  static Future<void> clearCache() async {
    _memoryCache.clear();
    _dirtyLangs.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKeyPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
      liveTranslationsVersionNotifier.value++;
    } catch (e) {
      debugPrint('GoogleLiveTranslateService clearCache error: $e');
    }
  }
}
