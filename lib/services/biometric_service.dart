import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefBiometricEnabledKey = 'tally_biometric_enabled';
  static const String _prefBiometricUserKey = 'tally_biometric_username';

  /// Checks if the device has biometric or screen lock hardware available and supported.
  static Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (e) {
      debugPrint('BiometricService.isDeviceSupported error: $e');
      return false;
    }
  }

  /// Returns list of enrolled biometrics (e.g. fingerprint, face).
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('BiometricService.getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Checks if user has toggled biometric unlock ON in Tally settings.
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefBiometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Retrieves the username associated with biometric unlock.
  static Future<String?> getSavedBiometricUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefBiometricUserKey);
    } catch (e) {
      return null;
    }
  }

  /// Sets whether biometric / screen lock unlock is enabled, saving the user association.
  static Future<void> setBiometricEnabled(bool enabled, {String? username}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefBiometricEnabledKey, enabled);
      if (enabled && username != null && username.isNotEmpty) {
        await prefs.setString(_prefBiometricUserKey, username);
      } else if (!enabled) {
        await prefs.remove(_prefBiometricUserKey);
      }
    } catch (e) {
      debugPrint('BiometricService.setBiometricEnabled error: $e');
    }
  }

  /// Prompts the native biometric / screen lock modal (Face ID, Fingerprint, or Device PIN).
  static Future<bool> authenticate({String reason = 'Unlock Tally Vault'}) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService.authenticate PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('BiometricService.authenticate error: $e');
      return false;
    }
  }
}
