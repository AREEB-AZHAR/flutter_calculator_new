import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppIconService {
  static const MethodChannel _channel = MethodChannel('com.areeb.tally/app_icon');

  /// Dynamically changes the Android launcher icon to 'Ledger', 'Paper', or 'Ink'.
  static Future<bool> setAppIcon(String iconName) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('setAppIcon', {'iconName': iconName});
        return result ?? false;
      } catch (e) {
        debugPrint('AppIconService: Failed to set app icon to $iconName: $e');
        return false;
      }
    }
    return false;
  }

  /// Returns the currently active launcher icon alias ('Ledger', 'Paper', or 'Ink').
  static Future<String> getCurrentIcon() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<String>('getCurrentIcon');
        return result ?? 'Ledger';
      } catch (e) {
        debugPrint('AppIconService: Failed to get current app icon: $e');
        return 'Ledger';
      }
    }
    return 'Ledger';
  }
}
