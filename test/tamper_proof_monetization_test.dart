import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/monetization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MonetizationService.resetPurchases();
  });

  group('Cryptographic HMAC Anti-Tamper & Security Integrity Tests', () {
    test('Legitimate unlockPro signs entitlements with valid HMAC signature', () async {
      const user = 'alice_valid';
      await MonetizationService.loadUserEntitlements(user);
      expect(MonetizationService.isPro, isFalse);

      // Legitimate purchase unlock
      await MonetizationService.unlockPro();
      expect(MonetizationService.isPro, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final sig = prefs.getString('tally_monetization_sig_$user');
      expect(sig, isNotNull);
      expect(sig!.length, equals(64)); // SHA256 hex string is 64 characters

      // Re-loading legitimate state preserves Pro status
      await MonetizationService.loadUserEntitlements(user);
      expect(MonetizationService.isPro, isTrue);
    });

    test('Attacker modifying SharedPreferences XML directly is detected and revoked to Free', () async {
      const user = 'hacker_bob';
      await MonetizationService.loadUserEntitlements(user);
      expect(MonetizationService.isPro, isFalse);

      final prefs = await SharedPreferences.getInstance();
      // Simulating external tampering (e.g., via rooted device file editor or XML injection)
      await prefs.setBool('tally_pro_unlocked_$user', true);
      // Notice: No valid HMAC signature was written by MonetizationService!

      // Loading the tampered account must detect the signature absence/mismatch
      await MonetizationService.loadUserEntitlements(user);

      // Entitlement must be REVOKED to Free tier immediately
      expect(MonetizationService.isPro, isFalse);
      expect(MonetizationService.isAdFree, isFalse);
      expect(prefs.getBool('tally_pro_unlocked_$user'), isNull);
    });

    test('Attacker forging an invalid signature string is detected and revoked to Free', () async {
      const user = 'hacker_charlie';
      await MonetizationService.loadUserEntitlements(user);

      final prefs = await SharedPreferences.getInstance();
      // Forging both the boolean and a fake signature
      await prefs.setBool('tally_pro_unlocked_$user', true);
      await prefs.setString('tally_monetization_sig_$user', 'deadbeef0000111122223333444455556666777788889999aaaabbbbccccdddd');

      // Attempt to load the forged account
      await MonetizationService.loadUserEntitlements(user);

      // Entitlement must fail cryptographic validation and revert to Free tier
      expect(MonetizationService.isPro, isFalse);
      expect(MonetizationService.isAdFree, isFalse);
      expect(prefs.getBool('tally_pro_unlocked_$user'), isNull);
      expect(prefs.getString('tally_monetization_sig_$user'), isNull);
    });

    test('Attacker tampering theme passes count is sanitized back to 0', () async {
      const user = 'hacker_dave';
      await MonetizationService.loadUserEntitlements(user);

      final prefs = await SharedPreferences.getInstance();
      // Injecting 999 free passes without valid HMAC signature
      await prefs.setInt('tally_theme_passes_$user', 999);

      await MonetizationService.loadUserEntitlements(user);

      expect(MonetizationService.themePassesNotifier.value, equals(0));
      expect(MonetizationService.hasThemePass, isFalse);
      expect(prefs.getInt('tally_theme_passes_$user'), isNull);
    });

    test('Legitimate grantThemePass updates and signs theme passes correctly', () async {
      const user = 'eve_legit';
      await MonetizationService.loadUserEntitlements(user);

      await MonetizationService.grantThemePass(2);
      expect(MonetizationService.themePassesNotifier.value, equals(2));
      expect(MonetizationService.hasThemePass, isTrue);

      // Re-loading verifies signature and keeps 2 passes
      await MonetizationService.loadUserEntitlements(user);
      expect(MonetizationService.themePassesNotifier.value, equals(2));
      expect(MonetizationService.hasThemePass, isTrue);
    });
  });
}
