import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/geo_location_service.dart';
import 'package:balance_tracker/services/insights_engine.dart';
import 'package:balance_tracker/services/language_service.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppState.currentUser = 'test_user';
    AppState.currencyNotifier.value = '\$';
  });

  group('GeoLocationService & Regional Currency Tests', () {
    test('GeoLocationService formats localized tier pricing and period strings', () {
      final usdPrice = GeoLocationService.formatLocalizedTierPrice(2.99, '\$');
      expect(usdPrice, '\$2.99');

      final eurPrice = GeoLocationService.formatLocalizedTierPrice(2.99, '€');
      expect(eurPrice, '€2.99');

      final pkrPrice = GeoLocationService.formatLocalizedTierPrice(2.99, '₨');
      expect(pkrPrice, '₨850');

      final formattedMonth = GeoLocationService.formatTierWithPeriod(2.99, '/mo', '₨');
      expect(formattedMonth, '₨850 /mo');

      final formattedAnnual = GeoLocationService.formatTierWithPeriod(19.99, '/yr', '₹');
      expect(formattedAnnual, '₹1,699 /yr');

      final formattedLifetime = GeoLocationService.formatTierWithPeriod(39.99, '', '\$');
      expect(formattedLifetime, '\$39.99');
    });
  });

  group('InsightsEngine Currency Parameter Tests', () {
    test('generateReport incorporates provided regional currency symbol in advice and projections', () {
      final now = DateTime.now();
      final txs = [
        Transaction(
          id: 'tx1',
          title: 'Consulting Fee',
          amount: 50000.0,
          date: DateTime(now.year, now.month, 1),
          isIncome: true,
          category: 'Salary',
          account: 'Main Bank',
        ),
        Transaction(
          id: 'tx2',
          title: 'Office Rent',
          amount: 25000.0,
          date: DateTime(now.year, now.month, 2),
          isIncome: false,
          category: 'Housing & Rent',
          account: 'Main Bank',
        ),
      ];

      final loans = [
        Loan(
          id: 'l1',
          title: 'Equipment Loan',
          personName: 'Vendor',
          amount: 10000.0,
          dueDate: now.add(const Duration(days: 30)),
          type: 'payable',
        ),
      ];

      final goals = [
        SavingsGoal(
          id: 'g1',
          title: 'Emergency Fund',
          target: 100000.0,
          saved: 40000.0,
          dueDate: now.add(const Duration(days: 60)),
        ),
      ];

      final report = InsightsEngine.generateReport(
        transactions: txs,
        loans: loans,
        budgets: {'Housing & Rent': 30000.0},
        goals: goals,
        horizon: TimeHorizon.monthly,
        periodOffset: 0,
        currency: '₨',
      );

      expect(report.totalInflow, 50000.0);
      expect(report.totalOutflow, 25000.0);
      expect(report.netSavings, 25000.0);
      expect(report.loanInsight.payoffAdvice, contains('₨'));
      expect(report.goalInsight.motivationalSummary, contains('₨'));
      expect(report.accountantSummary, isNotEmpty);
    });
  });

  group('ProfileScreen Settings Menu Virtualization & Categorization Tests', () {
    testWidgets('Opening Settings menu displays 3 categorized tabs and allows switching', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open Settings popup by tapping settings button in profile screen
      final settingsIconFinder = find.byIcon(Icons.settings);
      expect(settingsIconFinder, findsOneWidget);
      await tester.tap(settingsIconFinder);
      await tester.pumpAndSettle();

      // Check that the 3 categorized segmented tabs exist
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Cloud & Data'), findsOneWidget);

      // Tab 0 (Appearance) is active by default
      expect(find.text('What Each Setting Does'), findsOneWidget);
      expect(find.text('BRAND PALETTES (INSTANT IN-APP)'), findsOneWidget);
      expect(find.text('Ledger'), findsOneWidget);
      expect(find.text('Explore 6 Pro Brand Themes'), findsOneWidget);

      // Tap on Security tab
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();

      expect(find.text('PROFILE & IDENTITY'), findsOneWidget);
      expect(find.text('Account Security & Lock'), findsOneWidget);

      // Tap on Cloud & Data tab
      await tester.tap(find.text('Cloud & Data'));
      await tester.pumpAndSettle();

      expect(find.text('PRO & AD-FREE MEMBERSHIP'), findsOneWidget);
      expect(find.text('INTERACTIVE ONBOARDING TOURS'), findsOneWidget);
      expect(find.text(LanguageService.tr('pro_subscriptions_title')), findsOneWidget);
      expect(find.text(LanguageService.tr('replay_tours')), findsOneWidget);
    });

    testWidgets('Opening Features Guide modal displays virtualized list items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final guideIconFinder = find.byIcon(Icons.auto_stories_rounded);
      expect(guideIconFinder, findsOneWidget);
      await tester.tap(guideIconFinder);
      await tester.pumpAndSettle();

      // Verify guide modal header and virtualized items
      expect(find.text('Features & Settings Guide'), findsOneWidget);
      expect(find.text('Brand Palettes & Themes'), findsOneWidget);
      expect(find.text('Launcher App Icons'), findsOneWidget);
    });
  });
}
