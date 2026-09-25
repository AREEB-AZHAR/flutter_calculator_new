import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/utils/password_validator.dart';
import 'package:balance_tracker/services/monetization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Strong Password Validation Tests', () {
    test('Rejects password shorter than 10 characters', () {
      final res = PasswordValidator.validate('Abc!123'); // length 7
      expect(res.isValid, isFalse);
      expect(res.hasMinLength, isFalse);
      expect(res.missingRequirements, contains('At least 10 characters long'));
    });

    test('Rejects password missing uppercase letters', () {
      final res = PasswordValidator.validate('abcdef!1234'); // no uppercase
      expect(res.isValid, isFalse);
      expect(res.hasUppercase, isFalse);
      expect(res.missingRequirements, contains('At least 1 uppercase letter (A-Z)'));
    });

    test('Rejects password missing lowercase letters', () {
      final res = PasswordValidator.validate('ABCDEFG!1234'); // no lowercase
      expect(res.isValid, isFalse);
      expect(res.hasLowercase, isFalse);
      expect(res.missingRequirements, contains('At least 1 lowercase letter (a-z)'));
    });

    test('Rejects password missing special characters', () {
      final res = PasswordValidator.validate('Abcdefgh1234'); // no special char
      expect(res.isValid, isFalse);
      expect(res.hasSpecialChar, isFalse);
      expect(res.missingRequirements, contains('At least 1 special character (!@#\$%^&*...)'));
    });

    test('Rejects password with fewer than 3 numbers', () {
      final res = PasswordValidator.validate('SecurePass!12'); // only 2 digits
      expect(res.isValid, isFalse);
      expect(res.hasThreeDigits, isFalse);
      expect(res.digitCount, equals(2));
      expect(res.missingRequirements.any((m) => m.contains('At least 3 numbers')), isTrue);
    });

    test('Accepts valid strong password with all criteria satisfied', () {
      final res = PasswordValidator.validate('SuperSecret!123'); // 15 chars, Upper, Lower, !, 3 digits
      expect(res.isValid, isTrue);
      expect(res.hasMinLength, isTrue);
      expect(res.hasUppercase, isTrue);
      expect(res.hasLowercase, isTrue);
      expect(res.hasSpecialChar, isTrue);
      expect(res.hasThreeDigits, isTrue);
      expect(res.missingRequirements, isEmpty);
    });

    test('Validates email format correctly', () {
      expect(PasswordValidator.isValidEmail('user@example.com'), isTrue);
      expect(PasswordValidator.isValidEmail('areeb.finance@domain.co.uk'), isTrue);
      expect(PasswordValidator.isValidEmail('notanemail'), isFalse);
      expect(PasswordValidator.isValidEmail('missing@domain'), isFalse);
      expect(PasswordValidator.isValidEmail(''), isFalse);
    });
  });

  group('Monetization VIP Promo Code & Reset Testing', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await MonetizationService.initialize();
      await MonetizationService.resetPurchases();
    });

    test('Initial free tier is not Pro and not Ad-free', () {
      expect(MonetizationService.isPro, isFalse);
      expect(MonetizationService.isAdFree, isFalse);
    });

    test('Unlocks Pro with PROVIP promo code', () async {
      final result = await MonetizationService.redeemPromoCode('PROVIP');
      expect(result, isNotNull);
      expect(MonetizationService.isPro, isTrue);
      expect(MonetizationService.isAdFree, isTrue);
    });

    test('Resets VIP and Pro status with RESETVIP promo code', () async {
      // First unlock Pro
      await MonetizationService.unlockPro();
      expect(MonetizationService.isPro, isTrue);

      // Now reset via promo code
      final resetResult = await MonetizationService.redeemPromoCode('RESETVIP');
      expect(resetResult, contains('reset to Free tier'));
      expect(MonetizationService.isPro, isFalse);
      expect(MonetizationService.isAdFree, isFalse);
    });

    test('Resets VIP and Pro status with RESET promo code', () async {
      await MonetizationService.unlockPro();
      expect(MonetizationService.isPro, isTrue);

      final resetResult = await MonetizationService.redeemPromoCode('RESET');
      expect(resetResult, contains('reset to Free tier'));
      expect(MonetizationService.isPro, isFalse);
      expect(MonetizationService.isAdFree, isFalse);
    });

    test('Resets VIP with resetPurchases direct method', () async {
      await MonetizationService.unlockPro();
      expect(MonetizationService.isPro, isTrue);

      await MonetizationService.resetPurchases();
      expect(MonetizationService.isPro, isFalse);
      expect(MonetizationService.isAdFree, isFalse);
    });
  });
}
