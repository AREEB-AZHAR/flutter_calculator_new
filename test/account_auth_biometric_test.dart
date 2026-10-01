import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/services/biometric_service.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/screens/login_screen.dart';
import 'package:balance_tracker/screens/main_nav_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.database;
    await AppState.clearUserSession();
  });

  group('New Account Registration and Case-Insensitive Login Tests', () {
    test('Database: Register user with mixed case and authenticate across all case variations', () async {
      final db = AppDatabase.instance;
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final username = 'NewTester_$uniqueId';
      final email = 'NewUser_$uniqueId@Domain.Com';
      const password = 'SecurePassword!123';

      final registered = await db.registerUser(
        username: username,
        password: password,
        email: email,
      );
      expect(registered, isTrue, reason: 'Registration should succeed');

      // 1. Authenticate with exact username
      final authExact = await db.authenticateUser(username, password);
      expect(authExact, isTrue, reason: 'Auth by exact username should succeed');

      // 2. Authenticate with lowercase username
      final authLower = await db.authenticateUser(username.toLowerCase(), password);
      expect(authLower, isTrue, reason: 'Auth by lowercase username should succeed');

      // 3. Authenticate with uppercase username
      final authUpper = await db.authenticateUser(username.toUpperCase(), password);
      expect(authUpper, isTrue, reason: 'Auth by uppercase username should succeed');

      // 4. Authenticate with surrounding whitespace
      final authSpaced = await db.authenticateUser('   $username   ', password);
      expect(authSpaced, isTrue, reason: 'Auth by spaced username should succeed');

      // 5. Authenticate with exact email
      final authEmailExact = await db.authenticateUser(email, password);
      expect(authEmailExact, isTrue, reason: 'Auth by exact email should succeed');

      // 6. Authenticate with lowercase email
      final authEmailLower = await db.authenticateUser(email.toLowerCase(), password);
      expect(authEmailLower, isTrue, reason: 'Auth by lowercase email should succeed');

      // 7. Authenticate with uppercase email
      final authEmailUpper = await db.authenticateUser(email.toUpperCase(), password);
      expect(authEmailUpper, isTrue, reason: 'Auth by uppercase email should succeed');

      // 8. Canonical username resolution across varying cases
      final canonicalFromLower = await db.getUsernameForIdentifier(username.toLowerCase());
      expect(canonicalFromLower, equals(username));

      final canonicalFromUpperEmail = await db.getUsernameForIdentifier(email.toUpperCase());
      expect(canonicalFromUpperEmail, equals(username));

      // 9. Case-insensitive duplicate registration prevention
      final dupUsername = await db.registerUser(
        username: username.toLowerCase(),
        password: 'AnotherPassword!123',
        email: 'different_$uniqueId@domain.com',
      );
      expect(dupUsername, isFalse, reason: 'Duplicate username in lowercase should be rejected');

      final dupEmail = await db.registerUser(
        username: 'DistinctUser_$uniqueId',
        password: 'AnotherPassword!123',
        email: email.toUpperCase(),
      );
      expect(dupEmail, isFalse, reason: 'Duplicate email in uppercase should be rejected');
    });

    test('Database: Google account registration persists email column and handles case-insensitivity', () async {
      final db = AppDatabase.instance;
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final googleEmail = 'GoogleUser_$uniqueId@Gmail.Com';
      const displayName = 'Google Tester';

      final googleAuthSuccess = await db.authenticateOrRegisterGoogleUser(
        email: googleEmail,
        displayName: displayName,
      );
      expect(googleAuthSuccess, isTrue);

      // Verify email column is persisted and populated
      final userRecord = await db.getUserByEmail(googleEmail.toLowerCase());
      expect(userRecord, isNotNull);
      expect(userRecord!['email'], equals(googleEmail.trim().toLowerCase()));

      final userEmail = await db.getUserEmail(googleEmail);
      expect(userEmail, equals(googleEmail.trim().toLowerCase()));

      // Verify canonical username resolution for Google account
      final canonical = await db.getUsernameForIdentifier(googleEmail.toLowerCase());
      expect(canonical, equals(googleEmail.trim()));
    });

    test('Database: Password recovery by email works case-insensitively', () async {
      final db = AppDatabase.instance;
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final username = 'RecoveryUser_$uniqueId';
      final email = 'Recovery_$uniqueId@Example.Com';
      const initialPass = 'InitialPass!123';
      const newPass = 'UpdatedPass!456';

      await db.registerUser(username: username, password: initialPass, email: email);

      // Update password using lowercase email
      final updated = await db.updatePasswordByEmail(email.toLowerCase(), newPass);
      expect(updated, isTrue);

      // Authenticate with new password using original username
      final authWithNewPass = await db.authenticateUser(username, newPass);
      expect(authWithNewPass, isTrue);

      // Verify old password is now invalid
      final authWithOldPass = await db.authenticateUser(username, initialPass);
      expect(authWithOldPass, isFalse);
    });
  });

  group('Biometric Account Switching & Credential Isolation Tests', () {
    test('Logging into new account does not retain first account biometric credentials', () async {
      // 1. Account 1 enables biometrics
      const user1 = 'User1_Alpha';
      await BiometricService.setBiometricEnabled(true, username: user1);
      await BiometricService.syncUserSession(user1);

      expect(await BiometricService.isBiometricEnabled(), isTrue);
      expect(await BiometricService.getSavedBiometricUser(), equals(user1));

      // 2. User 2 (new account without biometrics) logs in
      const user2 = 'User2_Beta';
      await BiometricService.syncUserSession(user2);

      // User 2 MUST NOT inherit User 1's biometric unlock credentials on logout!
      expect(await BiometricService.isBiometricEnabled(), isFalse,
          reason: 'Biometric unlock must be false when current user does not have it enabled');
      expect(await BiometricService.getSavedBiometricUser(), isNull,
          reason: 'Saved biometric user must be cleared so User 1 is not offered to User 2');
      expect(await BiometricService.getLastLoggedInUser(), equals(user2));

      // 3. User 2 is prompted and configures biometrics for their account
      expect(await BiometricService.hasPromptedUser(user2), isFalse);
      await BiometricService.markUserPrompted(user2);
      expect(await BiometricService.hasPromptedUser(user2), isTrue);

      await BiometricService.setBiometricEnabled(true, username: user2);
      await BiometricService.syncUserSession(user2);

      // Now User 2 is the active biometric account
      expect(await BiometricService.isBiometricEnabled(), isTrue);
      expect(await BiometricService.getSavedBiometricUser(), equals(user2));
      expect(await BiometricService.isBiometricEnabled(username: user2), isTrue);
      expect(await BiometricService.isBiometricEnabled(username: user1), isTrue);

      // 4. Switching back to User 1 restores User 1 as the active biometric user
      await BiometricService.syncUserSession(user1);
      expect(await BiometricService.isBiometricEnabled(), isTrue);
      expect(await BiometricService.getSavedBiometricUser(), equals(user1));
      expect(await BiometricService.getLastLoggedInUser(), equals(user1));
    });

    testWidgets('Widget: Register new account, logout, and verify LoginScreen does not prompt wrong account', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Precondition: Suppose a previous user had biometrics enabled
      await BiometricService.setBiometricEnabled(true, username: 'OldAccount');
      await BiometricService.syncUserSession('OldAccount');
      expect(await BiometricService.getSavedBiometricUser(), equals('OldAccount'));

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to registration mode
      final switchBtn = find.text('Need an account? Register with Email');
      expect(switchBtn, findsOneWidget);
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      final unique = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'newuser$unique@domain.com';
      final testUser = 'NewUser$unique';
      const testPass = 'StrongPass!123';

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), testEmail);
      await tester.enterText(textFields.at(1), testUser);
      await tester.enterText(textFields.at(2), testPass);
      await tester.enterText(textFields.at(3), testPass);
      await tester.pump();

      final submitBtn = find.text('Create Ledger Account');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);

      for (int i = 0; i < 60; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(MainNavScreen).evaluate().isNotEmpty) break;
      }

      expect(AppState.currentUser, equals(testUser));
      expect(find.byType(MainNavScreen), findsOneWidget);

      // Verify that after registering NewUser, OldAccount's biometric credentials were cleared!
      expect(await BiometricService.getSavedBiometricUser(), isNull);
      expect(await BiometricService.isBiometricEnabled(), isFalse);
      expect(await BiometricService.getLastLoggedInUser(), equals(testUser));

      // Log out
      final BuildContext navContext = tester.element(find.byType(MainNavScreen));
      await AppState.logout(navContext);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(AppState.currentUser, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);

      // On LoginScreen, OldAccount MUST NOT appear in biometric button
      expect(find.textContaining('OldAccount'), findsNothing);
      expect(find.textContaining('Unlock with Screen Lock'), findsNothing,
          reason: 'Biometric unlock button should not appear for an account that does not have biometrics enabled');
    });
  });
}
