import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/utils/image_helper.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/screens/premium_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MonetizationService.initialize();
    await MonetizationService.resetPurchases();
  });

  group('ImageHelper Tests', () {
    test('isNetworkImage correctly classifies URLs and local files', () {
      expect(ImageHelper.isNetworkImage('https://lh3.googleusercontent.com/a/abc=s96-c'), isTrue);
      expect(ImageHelper.isNetworkImage('http://example.com/avatar.jpg'), isTrue);
      expect(ImageHelper.isNetworkImage('C:\\Users\\user\\Pictures\\avatar.png'), isFalse);
      expect(ImageHelper.isNetworkImage('/data/user/0/app/cache/photo.jpg'), isFalse);
      expect(ImageHelper.isNetworkImage('assets/images/default_avatar.png'), isFalse);
      expect(ImageHelper.isNetworkImage(''), isFalse);
      expect(ImageHelper.isNetworkImage(null), isFalse);
    });

    test('getProfileImageProvider returns appropriate ImageProvider instance', () {
      // 1. Null or empty path returns fallback AssetImage
      final fallbackProvider = ImageHelper.getProfileImageProvider(null);
      expect(fallbackProvider, isA<AssetImage>());
      expect((fallbackProvider as AssetImage).assetName, equals('assets/images/default_avatar.png'));

      final emptyProvider = ImageHelper.getProfileImageProvider('');
      expect(emptyProvider, isA<AssetImage>());

      // 2. HTTP/HTTPS path returns NetworkImage
      final networkProvider = ImageHelper.getProfileImageProvider('https://lh3.googleusercontent.com/test.jpg');
      expect(networkProvider, isA<NetworkImage>());
      expect((networkProvider as NetworkImage).url, equals('https://lh3.googleusercontent.com/test.jpg'));

      // 3. Local file path returns FileImage if file exists
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_avatar.png')..writeAsStringSync('dummy');
      final fileProvider = ImageHelper.getProfileImageProvider(tempFile.path);
      expect(fileProvider, isA<FileImage>());
      tempDir.deleteSync(recursive: true);
    });
  });

  group('PremiumScreen Widget Tests', () {
    testWidgets('Renders Tally Pro & VIP screen elements, tiers, and Google Pay CTA', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PremiumScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check App Bar and title
      expect(find.text('Tally Pro & VIP'), findsOneWidget);
      expect(find.text('Promo Code'), findsOneWidget);

      // Check Plan cards
      expect(find.text('Tally Pro Monthly'), findsOneWidget);
      expect(find.text('\$4.99 / mo'), findsOneWidget);
      expect(find.text('Tally Pro Yearly'), findsOneWidget);
      expect(find.text('\$49.90 / yr'), findsOneWidget);
      expect(find.text('Tally Pro Lifetime Access'), findsOneWidget);
      expect(find.text('\$47.88'), findsOneWidget);
      expect(find.text('☕ Buy the Developer a Coffee'), findsOneWidget);
      expect(find.text('\$1.99'), findsOneWidget);

      // Check Google Pay CTA button
      expect(find.textContaining('Pay with Google Pay'), findsOneWidget);

      // Check Feature section
      expect(find.text('What\'s Included'), findsOneWidget);
      expect(find.text('100% Ad-Free Experience'), findsOneWidget);
      expect(find.text('Predictive Insights & Velocity'), findsOneWidget);

      // Check Developer & QA Testing Mode section
      expect(find.text('Reset VIP Subscription (Developer Test Mode)'), findsOneWidget);
    });

    testWidgets('Tapping plan selection changes active tier', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PremiumScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Buy Coffee tier
      await tester.tap(find.text('☕ Buy the Developer a Coffee'));
      await tester.pumpAndSettle();

      // Verify Google Pay button text reflects $1.99
      expect(find.text('Pay with Google Pay • \$1.99'), findsOneWidget);

      // Tap on Tally Pro Yearly tier
      await tester.tap(find.text('Tally Pro Yearly'));
      await tester.pumpAndSettle();

      // Verify Google Pay button text reflects $49.90 / yr
      expect(find.text('Pay with Google Pay • \$49.90 / yr'), findsOneWidget);

      // Tap on Tally Pro Lifetime Access tier
      await tester.tap(find.text('Tally Pro Lifetime Access'));
      await tester.pumpAndSettle();

      // Verify Google Pay button text reflects $47.88
      expect(find.text('Pay with Google Pay • \$47.88'), findsOneWidget);
    });

    testWidgets('Reset Purchases button in developer mode resets VIP state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // First unlock Pro
      await MonetizationService.unlockPro();
      expect(MonetizationService.isPro, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: PremiumScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Pro is active in header
      expect(find.text('TALLY PRO MEMBER'), findsOneWidget);
      expect(find.text('All Pro Features Unlocked'), findsOneWidget);

      // Tap Reset VIP Subscription (Developer Test Mode)
      await tester.tap(find.text('Reset VIP Subscription (Developer Test Mode)'));
      await tester.pumpAndSettle();

      // Verify Pro is reset
      expect(MonetizationService.isPro, isFalse);
    });
  });
}

