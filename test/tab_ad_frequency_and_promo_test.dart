import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/ad_service.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/in_app_purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MonetizationService.resetPurchases();
    AdService.resetTabAdCountersForTesting();
  });

  group('Tab Switch Ad Frequency Tests', () {
    testWidgets('1st switch always triggers ad, then every 4th to 5th switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await AdService.showTabSwitchInterstitialAd(
                      context: context,
                      onComplete: () {},
                    );
                  },
                  child: const Text('Switch Tab'),
                ),
              );
            },
          ),
        ),
      );

      // Helper to simulate a tab switch
      Future<void> triggerSwitch() async {
        await tester.tap(find.text('Switch Tab'));
        await tester.pump();
      }

      // Switch 1: MUST always trigger ad
      await triggerSwitch();
      // On headless test, FullscreenInterstitialAdDialog appears or onComplete is called
      expect(find.text('AD • SPONSORED'), findsOneWidget);
      // Dismiss dialog
      Navigator.of(tester.element(find.text('AD • SPONSORED'))).pop();
      await tester.pumpAndSettle();

      // Switch 2, 3, 4: Should NOT show any ad
      await triggerSwitch();
      expect(find.text('AD • SPONSORED'), findsNothing);

      await triggerSwitch();
      expect(find.text('AD • SPONSORED'), findsNothing);

      await triggerSwitch();
      expect(find.text('AD • SPONSORED'), findsNothing);

      // Switch 5: 4th switch since last ad -> MUST trigger ad!
      await triggerSwitch();
      expect(find.text('AD • SPONSORED'), findsOneWidget);

      // Dismiss dialog
      Navigator.of(tester.element(find.text('AD • SPONSORED'))).pop();
      await tester.pumpAndSettle();

      // Next threshold alternated to 5:
      // Switches 6, 7, 8, 9 (1, 2, 3, 4 since last ad) should NOT show ad
      for (int i = 0; i < 4; i++) {
        await triggerSwitch();
        expect(find.text('AD • SPONSORED'), findsNothing);
      }

      // Switch 10 (5th since last ad): MUST trigger ad!
      await triggerSwitch();
      expect(find.text('AD • SPONSORED'), findsOneWidget);
    });

    testWidgets('Pro / Ad-Free users completely bypass transition ads', (tester) async {
      await MonetizationService.unlockPro();
      expect(MonetizationService.isAdFree, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await AdService.showTabSwitchInterstitialAd(
                      context: context,
                      onComplete: () {},
                    );
                  },
                  child: const Text('Switch Tab'),
                ),
              );
            },
          ),
        ),
      );

      // Even on switch 1, Pro users bypass immediately
      await tester.tap(find.text('Switch Tab'));
      await tester.pump();
      expect(find.text('AD • SPONSORED'), findsNothing);
    });
  });

  group('Promo Code Redemption Tests', () {
    test('PROVIP successfully unlocks Tally Pro', () async {
      expect(MonetizationService.isProUnlockedNotifier.value, isFalse);
      final result = await MonetizationService.redeemPromoCode('PROVIP');
      expect(result, isNotNull);
      expect(result, contains('Tally Pro fully unlocked'));
      expect(MonetizationService.isProUnlockedNotifier.value, isTrue);
    });

    test('NOADS successfully removes banner and transition ads', () async {
      expect(MonetizationService.isAdsRemovedNotifier.value, isFalse);
      final result = await MonetizationService.redeemPromoCode('noads');
      expect(result, isNotNull);
      expect(result, contains('Ads removed successfully'));
      expect(MonetizationService.isAdsRemovedNotifier.value, isTrue);
    });

    test('THEMEPASS grants 3 free theme change passes', () async {
      final initialPasses = MonetizationService.themePassesNotifier.value;
      final result = await MonetizationService.redeemPromoCode('THEMEPASS');
      expect(result, isNotNull);
      expect(MonetizationService.themePassesNotifier.value, equals(initialPasses + 3));
    });

    test('RESETVIP resets entitlements to free tier', () async {
      await MonetizationService.unlockPro();
      expect(MonetizationService.isProUnlockedNotifier.value, isTrue);

      final result = await MonetizationService.redeemPromoCode('RESETVIP');
      expect(result, isNotNull);
      expect(MonetizationService.isProUnlockedNotifier.value, isFalse);
    });
  });

  group('InAppPurchaseService Sandbox Mode Tests', () {
    test('buyProduct with allowSandboxSimulation completes and unlocks Pro', () async {
      await MonetizationService.resetPurchases();
      expect(MonetizationService.isProUnlockedNotifier.value, isFalse);

      final success = await InAppPurchaseService.instance.buyProduct(
        InAppPurchaseService.proYearlyId,
        allowSandboxSimulation: true,
      );

      expect(success, isTrue);
      expect(MonetizationService.isProUnlockedNotifier.value, isTrue);
    });

    test('buyProduct with allowSandboxSimulation removes ads', () async {
      await MonetizationService.resetPurchases();
      expect(MonetizationService.isAdsRemovedNotifier.value, isFalse);

      final success = await InAppPurchaseService.instance.buyProduct(
        InAppPurchaseService.removeAdsId,
        allowSandboxSimulation: true,
      );

      expect(success, isTrue);
      expect(MonetizationService.isAdsRemovedNotifier.value, isTrue);
    });
  });
}
