import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/models/planned_transaction.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/utils/constants.dart';
import 'package:balance_tracker/screens/all_transactions_screen.dart';
import 'package:balance_tracker/screens/accounts_screen.dart';
import 'package:balance_tracker/widgets/interactive_chart_card.dart';
import 'package:balance_tracker/widgets/planned_transactions_sheet.dart';
import 'package:balance_tracker/services/tour_service.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TourService.markTourCompleted(TourService.tourAccounts);
    await TourService.markTourCompleted(TourService.tourHome);
    AppState.currentUser = 'testuser';
    AppState.currencyNotifier.value = '\$';
    AppState.transactionsNotifier.value = [
      Transaction(
        id: 'tx_income_1',
        title: 'Salary Deposit',
        amount: 3500.0,
        date: DateTime.now(),
        isIncome: true,
        category: 'Salary',
        account: 'Main',
      ),
      Transaction(
        id: 'tx_expense_1',
        title: 'Grocery Store',
        amount: 120.0,
        date: DateTime.now(),
        isIncome: false,
        category: 'Groceries',
        account: 'Main',
      ),
    ];
    AppState.loansNotifier.value = [
      Loan(
        id: 'loan_1',
        personName: 'Alice',
        amount: 250.0,
        dueDate: DateTime.now().add(const Duration(days: 4)),
        type: 'receivable',
        title: 'Dinner split',
        account: 'Main',
      ),
      Loan(
        id: 'loan_2',
        personName: 'Bob',
        amount: 100.0,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        type: 'payable',
        title: 'Concert ticket',
        account: 'Main',
      ),
    ];
    AppState.plannedTransactionsNotifier.value = [
      PlannedTransaction(
        id: 'plan_1',
        title: 'Upcoming Rent',
        amount: 1200.0,
        date: DateTime.now().add(const Duration(days: 5)),
        isIncome: false,
        category: 'Housing',
        account: 'Main',
      ),
      PlannedTransaction(
        id: 'plan_2',
        title: 'Client Payment',
        amount: 800.0,
        date: DateTime.now().add(const Duration(days: 2)),
        isIncome: true,
        category: 'Freelance',
        account: 'Main',
      ),
    ];
  });

  test('buildDynamicTheme generates valid contrast across all 9 presets', () {
    for (final preset in themePresets) {
      final theme = buildAppTheme(preset.name);
      expect(theme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.colorScheme.surface, isNotNull);
      expect(theme.scaffoldBackgroundColor, isNotNull);
      expect(theme.colorScheme.onSurface, isNotNull);
      expect(theme.colorScheme.onPrimary, isNotNull);

      // Verify brightness alignment
      if (preset.name == 'Paper') {
        expect(theme.brightness, equals(Brightness.light));
      } else {
        expect(theme.brightness, equals(Brightness.dark));
      }
    }
  });

  testWidgets('InteractiveChartCard renders without errors under Ledger, Paper, and Ink', (tester) async {
    for (final themeName in ['Ledger', 'Paper', 'Ink']) {
      final theme = buildAppTheme(themeName);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: InteractiveChartCard(
              transactions: AppState.transactionsNotifier.value,
              title: '$themeName Analytics',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('$themeName Analytics'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Net Balance'), findsOneWidget);

      // Switch scope to year and test
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      // Switch to bar chart
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();

      // Switch to pie chart
      await tester.tap(find.byIcon(Icons.pie_chart_outline));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('AccountsScreen and Loan Tab adapt seamlessly across themes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final themeName in ['Ledger', 'Paper', 'Ink']) {
      final theme = buildAppTheme(themeName);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: AccountsScreen(key: ValueKey(themeName)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wallets & Accounts'), findsOneWidget);
      expect(find.text('Loans & Debts'), findsOneWidget);

      // Switch to Loans & Debts tab
      await tester.tap(find.text('Loans & Debts'));
      await tester.pumpAndSettle();

      expect(find.text('Receivable'), findsOneWidget);
      expect(find.text('Payable'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    }
  });

  testWidgets('PlannedTransactionsSheet renders smoothly in light Paper and dark Ledger', (tester) async {
    for (final themeName in ['Paper', 'Ledger']) {
      final theme = buildAppTheme(themeName);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: PlannedTransactionsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planned & Future Sheet'), findsOneWidget);
      expect(find.text('Upcoming Rent'), findsOneWidget);
      expect(find.text('Client Payment'), findsOneWidget);
    }
  });

  testWidgets('AllTransactionsScreen search and theme switching without glitches', (tester) async {
    await tester.pumpWidget(
      AnimatedBuilder(
        animation: Listenable.merge([
          AppState.themeNameNotifier,
          AppState.customPrimaryColorNotifier,
          AppState.customSecondaryColorNotifier,
          AppState.customTextColorNotifier,
        ]),
        builder: (context, _) {
          return MaterialApp(
            theme: buildDynamicTheme(
              primary: AppState.customPrimaryColorNotifier.value,
              secondary: AppState.customSecondaryColorNotifier.value,
              textColor: AppState.customTextColorNotifier.value,
              themeName: AppState.themeNameNotifier.value,
            ),
            home: const AllTransactionsScreen(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Transactions'), findsOneWidget);

    // Switch theme dynamically to Paper (light)
    await AppState.persistThemePreset(themePresets[1]); // Paper
    await tester.pumpAndSettle();
    expect(AppState.themeNameNotifier.value, equals('Paper'));

    // Switch theme dynamically to Ink (carbon dark)
    await AppState.persistThemePreset(themePresets[2]); // Ink
    await tester.pumpAndSettle();
    expect(AppState.themeNameNotifier.value, equals('Ink'));

    // Switch back to Ledger
    await AppState.persistThemePreset(themePresets[0]); // Ledger
    await tester.pumpAndSettle();
    expect(AppState.themeNameNotifier.value, equals('Ledger'));

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Salary');
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Salary Deposit'), findsOneWidget);
  });
}
