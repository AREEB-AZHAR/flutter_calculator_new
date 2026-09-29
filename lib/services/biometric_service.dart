import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefBiometricEnabledKey = 'tally_biometric_enabled';
  static const String _prefBiometricUserKey = 'tally_biometric_username';

  /// Checks if the device has biometric or screen lock hardware available and supported.
  static Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
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
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('BiometricService.getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Checks if user has toggled biometric unlock ON in Tally settings.
  static Future<bool> isBiometricEnabled({String? username}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (username != null && username.isNotEmpty) {
        return prefs.getBool('${_prefBiometricEnabledKey}_$username') ?? false;
      }
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
      if (username != null && username.isNotEmpty) {
        await prefs.setBool('${_prefBiometricEnabledKey}_$username', enabled);
        if (enabled) {
          await prefs.setString(_prefBiometricUserKey, username);
          await prefs.setBool(_prefBiometricEnabledKey, true);
        } else {
          final savedUser = prefs.getString(_prefBiometricUserKey);
          if (savedUser == username) {
            await prefs.remove(_prefBiometricUserKey);
            await prefs.setBool(_prefBiometricEnabledKey, false);
          }
        }
      } else {
        await prefs.setBool(_prefBiometricEnabledKey, enabled);
        if (!enabled) {
          await prefs.remove(_prefBiometricUserKey);
        }
      }
    } catch (e) {
      debugPrint('BiometricService.setBiometricEnabled error: $e');
    }
  }

  /// Prompts the native biometric / screen lock modal (Face ID, Fingerprint, or Device PIN).
  static Future<bool> authenticate({String reason = 'Unlock Tally Vault'}) async {
    if (kIsWeb) return false;
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

  static bool biometricPromptCheckedThisSession = false;

  /// Tracks whether the user explicitly triggered a logout.
  /// When true, prevents automatic biometric popups on the LoginScreen so the user
  /// isn't ambushed to re-enter an account they just logged out of.
  static bool isExplicitLogout = false;

  /// Resets the session prompt state and marks explicit logout.
  static void resetSessionPrompt() {
    biometricPromptCheckedThisSession = false;
    isExplicitLogout = true;
  }

  /// Displays the easy biometric login popup dialog to the user upon login.
  static Future<bool?> showBiometricSetupPrompt(BuildContext context) async {
    if (kIsWeb) return false;
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: onSurface.withValues(alpha: 0.12), width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.fingerprint_rounded, color: primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Easy Login Option',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like an easy login option by configuring biometric login or screen lock?',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: onSurface.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_open_rounded, color: primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unlock Tally instantly using Face ID, Fingerprint, or your device PIN without typing your password each time.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Configure Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
