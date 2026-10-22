import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/ad_service.dart';
import 'package:balance_tracker/widgets/ad_banner_widget.dart';
import 'package:balance_tracker/widgets/fullscreen_interstitial_ad_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MonetizationService.isProUnlockedNotifier.value = false;
    MonetizationService.isAdsRemovedNotifier.value = false;
  });

  group('Ad Density & Interstitial Tab Transitions Tests', () {
    testWidgets('AdBannerWidget renders enlarged banner for free tier users', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdBannerWidget(
              size: AdBannerSize.large,
              sponsorCategory: 'Test Sponsor APY',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AdBannerWidget), findsOneWidget);
      expect(find.text('Test Sponsor APY'), findsOneWidget);
      expect(find.text('Ad • Partner'), findsOneWidget);
    });

    testWidgets('AdBannerWidget collapses to SizedBox.shrink when Ad-Free is unlocked', (tester) async {
      MonetizationService.isAdsRemovedNotifier.value = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdBannerWidget(
              size: AdBannerSize.large,
              sponsorCategory: 'Test Sponsor APY',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Sponsor APY'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('FullscreenInterstitialAdDialog renders skip counter and dispatches onDismissed', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FullscreenInterstitialAdDialog.show(
                  context,
                  onDismissed: () {
                    dismissed = true;
                  },
                );
              },
              child: const Text('Launch Interstitial'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Interstitial'));
      await tester.pump(); // Start dialog
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FullscreenInterstitialAdDialog), findsOneWidget);
      expect(find.textContaining('Skip in'), findsOneWidget);
      expect(find.text('AD • SPONSORED'), findsOneWidget);

      // Fast forward past countdown (4 seconds)
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 100));

      // Close button appears
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('AdService.showTabSwitchInterstitialAd bypasses immediately for Pro subscribers', (tester) async {
      MonetizationService.isProUnlockedNotifier.value = true;
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AdService.showTabSwitchInterstitialAd(
                    context: context,
                    onComplete: () {
                      completed = true;
                    },
                  );
                },
                child: const Text('Switch Tab'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Switch Tab'));
      await tester.pump();

      expect(completed, isTrue);
      expect(find.byType(FullscreenInterstitialAdDialog), findsNothing);
    });
  });
}
