import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Logout & Biometric Lifecycle Tests', () {
    test('clearUserSession marks isExplicitLogout = true and nullifies user', () async {
      AppState.currentUser = 'test_user';
      BiometricService.isExplicitLogout = false;

      await AppState.clearUserSession();

      expect(AppState.currentUser, isNull);
      expect(BiometricService.isExplicitLogout, isTrue);
      expect(BiometricService.biometricPromptCheckedThisSession, isFalse);
      expect(AppState.themeNameNotifier.value, 'Ledger');
    });

    test('resetSessionPrompt sets isExplicitLogout to true', () {
      BiometricService.isExplicitLogout = false;
      BiometricService.biometricPromptCheckedThisSession = true;

      BiometricService.resetSessionPrompt();

      expect(BiometricService.isExplicitLogout, isTrue);
      expect(BiometricService.biometricPromptCheckedThisSession, isFalse);
    });

    test('isBiometricEnabled and savedBiometricUser behave consistently with user scoping', () async {
      SharedPreferences.setMockInitialValues({});
      await BiometricService.setBiometricEnabled(true, username: 'areeb');

      expect(await BiometricService.isBiometricEnabled(username: 'areeb'), isTrue);
      expect(await BiometricService.getSavedBiometricUser(), 'areeb');

      // Another user has biometrics disabled by default
      expect(await BiometricService.isBiometricEnabled(username: 'other_user'), isFalse);
    });
  });
}
