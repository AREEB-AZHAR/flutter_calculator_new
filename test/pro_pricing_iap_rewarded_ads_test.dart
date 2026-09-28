import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/in_app_purchase_service.dart';
import 'package:balance_tracker/widgets/fullscreen_30sec_ad_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MonetizationService.resetPurchases();
  });

  group('Recalculated Pro Pricing Matrix Tests', () {
    test('Pro pricing values follow consistent unit economics', () {
      expect(MonetizationService.proMonthlyPrice, equals(2.99));
      expect(MonetizationService.proYearlyPrice, equals(19.99));
      expect(MonetizationService.proLifetimePrice, equals(39.99));
      expect(MonetizationService.removeAdsPrice, equals(1.99));
      expect(MonetizationService.coffeeTipPrice, equals(2.99));

      // Lifetime ($39.99) is strictly greater than 1 Year ($19.99)
      expect(MonetizationService.proLifetimePrice > MonetizationService.proYearlyPrice, isTrue);

      // Yearly provides ~44% discount compared to 12 months ($35.88)
      final monthlyAnnualized = MonetizationService.proMonthlyPrice * 12;
      final discountPct = ((monthlyAnnualized - MonetizationService.proYearlyPrice) / monthlyAnnualized) * 100;
      expect(discountPct, greaterThan(40.0));
    });
  });

  group('Google Official Payment (InAppPurchaseService) Tests', () {
    test('Configures official product IDs correctly', () {
      expect(InAppPurchaseService.proMonthlyId, equals('tally_pro_monthly'));
      expect(InAppPurchaseService.proYearlyId, equals('tally_pro_yearly'));
      expect(InAppPurchaseService.proLifetimeId, equals('tally_pro_lifetime'));
      expect(InAppPurchaseService.removeAdsId, equals('tally_remove_ads'));
      expect(InAppPurchaseService.coffeeTipId, equals('tally_coffee_tip'));

      expect(InAppPurchaseService.productIds.contains('tally_pro_monthly'), isTrue);
      expect(InAppPurchaseService.productIds.contains('tally_pro_yearly'), isTrue);
      expect(InAppPurchaseService.productIds.contains('tally_pro_lifetime'), isTrue);
      expect(InAppPurchaseService.productIds.contains('tally_remove_ads'), isTrue);
      expect(InAppPurchaseService.productIds.contains('tally_coffee_tip'), isTrue);
    });

    test('Simulated / Fallback purchase execution unlocks entitlements properly', () async {
      await MonetizationService.resetPurchases();
      expect(MonetizationService.isPro, isFalse);

      // Simulate purchasing Pro Lifetime
      final success = await InAppPurchaseService.instance.buyProduct(InAppPurchaseService.proLifetimeId);
      expect(success, isTrue);
      expect(MonetizationService.isPro, isTrue);
      expect(MonetizationService.isAdFree, isTrue);
    });
  });

  group('Theme Passes & Rewarded Ads Unlocking Tests', () {
    test('Starts at 0 passes for new users', () {
      expect(MonetizationService.themePassesNotifier.value, equals(0));
      expect(MonetizationService.hasThemePass, isFalse);
    });

    test('Grants and consumes theme passes correctly', () async {
      await MonetizationService.grantThemePass(1);
      expect(MonetizationService.themePassesNotifier.value, equals(1));
      expect(MonetizationService.hasThemePass, isTrue);

      // Consume pass
      final consumed = await MonetizationService.consumeThemePass();
      expect(consumed, isTrue);
      expect(MonetizationService.themePassesNotifier.value, equals(0));
      expect(MonetizationService.hasThemePass, isFalse);

      // Consuming when 0 passes remaining returns false
      final consumedAgain = await MonetizationService.consumeThemePass();
      expect(consumedAgain, isFalse);
    });

    test('Pro subscribers bypass pass requirements', () async {
      await MonetizationService.unlockPro();
      expect(MonetizationService.isPro, isTrue);
      expect(MonetizationService.hasThemePass, isTrue);

      // Pro consumption always returns true and doesn't decrement
      final consumed = await MonetizationService.consumeThemePass();
      expect(consumed, isTrue);
      expect(MonetizationService.themePassesNotifier.value, equals(0));
    });

    test('Promo code THEMEPASS grants 3 passes', () async {
      final msg = await MonetizationService.redeemPromoCode('THEMEPASS');
      expect(msg, contains('3 Free Theme Change Passes'));
      expect(MonetizationService.themePassesNotifier.value, equals(3));
    });

    test('Reset purchases clears theme passes, pro status, and ad removal', () async {
      await MonetizationService.unlockPro();
      await MonetizationService.grantThemePass(2);
      expect(MonetizationService.isPro, isTrue);
      expect(MonetizationService.themePassesNotifier.value, equals(2));

      await MonetizationService.resetPurchases();
      expect(MonetizationService.isPro, isFalse);
      expect(MonetizationService.themePassesNotifier.value, equals(0));
      expect(MonetizationService.hasThemePass, isFalse);
    });
  });

  group('30-Second Fullscreen Rewarded Ad Widget Tests', () {
    testWidgets('Renders 30-second non-skippable countdown timer and partner information', (tester) async {
      bool rewardClaimed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Fullscreen30SecAdDialog(
              onRewardEarned: () {
                rewardClaimed = true;
              },
            ),
          ),
        ),
      );

      // Verify timer badge shows 30s countdown
      expect(find.text('Reward in 30s'), findsOneWidget);
      expect(find.text('Sponsored Offer • AdMob Video'), findsOneWidget);
      expect(find.text('Apex High-Yield Cash Vault'), findsOneWidget);
      expect(find.text('5.25% APY • ZERO FEES • FDIC INSURED'), findsOneWidget);
      expect(find.text('Please wait: 30s remaining (Non-Skippable)'), findsOneWidget);

      // Verify button is disabled initially
      final btnFinder = find.byType(ElevatedButton);
      final btn = tester.widget<ElevatedButton>(btnFinder);
      expect(btn.onPressed, isNull);

      expect(rewardClaimed, isFalse);
    });
  });
}
