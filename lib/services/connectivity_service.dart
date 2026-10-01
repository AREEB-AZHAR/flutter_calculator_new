import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to monitor real-time internet connectivity across all platforms.
class ConnectivityService {
  ConnectivityService._();

  /// Reactive notifier for online/offline connectivity state.
  static final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  static Timer? _timer;
  static bool _isChecking = false;

  /// Checks if active internet connectivity is available.
  static Future<bool> checkOnline() async {
    if (kIsWeb) {
      isOnlineNotifier.value = true;
      return true;
    }
    if (_isChecking) return isOnlineNotifier.value;
    _isChecking = true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (isOnlineNotifier.value != online) {
        isOnlineNotifier.value = online;
      }
      return online;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 2));
        final online = fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
        if (isOnlineNotifier.value != online) {
          isOnlineNotifier.value = online;
        }
        return online;
      } catch (_) {
        if (isOnlineNotifier.value != false) {
          isOnlineNotifier.value = false;
        }
        return false;
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Starts periodic connectivity checks.
  static void startMonitoring({Duration interval = const Duration(seconds: 12)}) {
    _timer?.cancel();
    checkOnline();
    _timer = Timer.periodic(interval, (_) => checkOnline());
  }

  /// Stops periodic checks.
  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Current synchronous connectivity reading.
  static bool get isOnline => isOnlineNotifier.value;
}
