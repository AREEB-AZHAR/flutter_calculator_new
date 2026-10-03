import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, high-performance live translation service utilizing Google Translate.
/// Features multi-tier caching (In-Memory LRU + Persistent SharedPreferences)
/// with request deduplication, silent offline fallback, and reactive notification.
class GoogleLiveTranslateService {
  GoogleLiveTranslateService._();

  static const String _prefsKeyPrefix = 'glt_cache_';
  static bool isEnabled = true;

  /// In-memory cache: targetLang -> (sourceText -> translatedText)
  static final Map<String, Map<String, String>> _memoryCache = {};

  /// In-flight requests deduplication: 'targetLang:sourceText' -> Future
  static final Map<String, Future<String?>> _inFlight = {};

  /// Notifier incremented whenever a new live translation is cached.
  /// UI widgets can listen to this to reactively update without navigation reload.
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
  static String? getCached(String text, {required String targetLang}) {
    if (!isEnabled || text.trim().isEmpty) return null;
    return _memoryCache[targetLang]?[text];
  }

  /// Translates text to the target language.
  /// 1. Returns from memory cache if available (0ms).
  /// 2. If not cached, fetches from Google Translate API.
  /// 3. Automatically caches result in memory and persistent storage.
  /// 4. If offline or error occurs, gracefully falls back to [fallback] or original [text].
  static Future<String> translate(
    String text, {
    required String targetLang,
    String? fallback,
  }) async {
    final trimmed = text.trim();
    if (!isEnabled || trimmed.isEmpty || targetLang == 'en') {
      return fallback ?? text;
    }

    // 1. Check in-memory cache
    final cached = getCached(trimmed, targetLang: targetLang);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 2. Check if identical request is already in-flight (deduplication)
    final flightKey = '$targetLang:$trimmed';
    if (_inFlight.containsKey(flightKey)) {
      final inFlightResult = await _inFlight[flightKey];
      return inFlightResult ?? (fallback ?? text);
    }

    // 3. Initiate network request
    final future = _fetchFromGoogle(trimmed, targetLang: targetLang);
    _inFlight[flightKey] = future;

    try {
      final result = await future;
      if (result != null && result.isNotEmpty) {
        _cacheTranslation(trimmed, result, targetLang: targetLang);
        liveTranslationsVersionNotifier.value++;
        return result;
      }
    } catch (e) {
      debugPrint('GoogleLiveTranslateService.translate error: $e');
    } finally {
      _inFlight.remove(flightKey);
    }

    return fallback ?? text;
  }

  /// Triggers an asynchronous translation in the background without blocking caller.
  /// When translation arrives, caches it and notifies [liveTranslationsVersionNotifier].
  static void translateAsyncAndNotify(String text, {required String targetLang}) {
    final trimmed = text.trim();
    if (!isEnabled || trimmed.isEmpty || targetLang == 'en') return;

    if (getCached(trimmed, targetLang: targetLang) != null) return;

    final flightKey = '$targetLang:$trimmed';
    if (_inFlight.containsKey(flightKey)) return;

    translate(trimmed, targetLang: targetLang).catchError((_) => text);
  }

  /// Network call to Google Translate endpoint with timeout & safety guards.
  static Future<String?> _fetchFromGoogle(String text, {required String targetLang}) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final request = await client.getUrl(uri);
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
      debugPrint('GoogleLiveTranslateService network warning: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// Saves the translation into RAM and persists asynchronously to SharedPreferences.
  static void _cacheTranslation(String source, String translated, {required String targetLang}) {
    _memoryCache[targetLang] ??= {};
    _memoryCache[targetLang]![source] = translated;

    // Asynchronously write to persistent storage
    SharedPreferences.getInstance().then((prefs) {
      final key = '$_prefsKeyPrefix$targetLang';
      final currentMap = _memoryCache[targetLang] ?? {};
      prefs.setString(key, jsonEncode(currentMap));
    }).catchError((e) {
      debugPrint('GoogleLiveTranslateService save cache error: $e');
    });
  }

  /// Clears in-memory and persistent translation cache.
  static Future<void> clearCache() async {
    _memoryCache.clear();
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
