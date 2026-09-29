import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/models/planned_transaction.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/screens/all_transactions_screen.dart';
import 'package:balance_tracker/screens/accounts_screen.dart';
import 'package:balance_tracker/widgets/interactive_chart_card.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:balance_tracker/services/tour_service.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz.initializeTimeZones();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TourService.markTourCompleted(TourService.tourAccounts);
    AppState.currentUser = 'test_loan_user';
    AppState.currencyNotifier.value = '\$';
    AppState.transactionsNotifier.value = [];
    AppState.loansNotifier.value = [];
    AppState.plannedTransactionsNotifier.value = [];
  });

  group('Loan Model & Data Operations', () {
    test('Loan serializes to and from JSON accurately', () {
      final now = DateTime.now();
      final loan = Loan(
        title: 'Dinner split',
        personName: 'Alex',
        amount: 45.50,
        dueDate: now.add(const Duration(days: 2)),
        type: 'receivable',
        notes: 'Italian restaurant',
        account: 'Cash',
      );

      expect(loan.isReceivable, isTrue);
      expect(loan.isPayable, isFalse);
      expect(loan.isSettled, isFalse);

      final json = loan.toJson();
      expect(json['personName'], 'Alex');
      expect(json['amount'], 45.50);
      expect(json['type'], 'receivable');

      final deserialized = Loan.fromJson(json);
      expect(deserialized.id, loan.id);
      expect(deserialized.personName, 'Alex');
      expect(deserialized.amount, 45.50);
      expect(deserialized.type, 'receivable');
    });

    test('Saving and toggling settled status updates SQLite and AppState', () async {
      final loan = Loan(
        title: 'Office supply reimbursement',
        personName: 'Office Dept',
        amount: 120.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        type: 'receivable',
      );

      await AppState.saveLoan('test_loan_user', loan);
      expect(AppState.loansNotifier.value.length, 1);
      expect(AppState.loansNotifier.value.first.personName, 'Office Dept');
      expect(AppState.loansNotifier.value.first.isSettled, isFalse);

      await AppState.toggleLoanSettled('test_loan_user', loan);
      expect(AppState.loansNotifier.value.first.isSettled, isTrue);

      await AppState.deleteLoan('test_loan_user', loan.id);
      expect(AppState.loansNotifier.value, isEmpty);
    });
  });

  group('Planned & Recurring Automation Engine', () {
    test('PlannedTransaction promotes to active transaction when due date is reached', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final planned = PlannedTransaction(
        title: 'Monthly Gym Subscription',
        amount: 35.0,
        date: yesterday,
        isIncome: false,
        category: 'Health & Wellness',
        account: 'Credit Card',
        recurrence: 'Monthly',
      );

      await AppDatabase.instance.savePlannedTransaction('test_loan_user', planned);
      AppState.plannedTransactionsNotifier.value = [planned];

      // Run automated due processor
      await AppState.checkAndProcessPlannedAndRecurring('test_loan_user');

      // 1. Transaction should now be active in the ledger
      expect(AppState.transactionsNotifier.value.any((t) => t.title == 'Monthly Gym Subscription'), isTrue);
      final activeTx = AppState.transactionsNotifier.value.firstWhere((t) => t.title == 'Monthly Gym Subscription');
      expect(activeTx.amount, 35.0);
      expect(activeTx.isIncome, isFalse);

      // 2. Next month should be staged automatically because recurrence is Monthly
      final updatedPlans = await AppDatabase.instance.loadPlannedTransactions('test_loan_user');
      expect(updatedPlans.any((p) => p.title == 'Monthly Gym Subscription'), isTrue);
      final nextPlan = updatedPlans.firstWhere((p) => p.title == 'Monthly Gym Subscription');
      expect(nextPlan.date.isAfter(DateTime.now()), isTrue);
    });
  });

  group('InteractiveChartCard & AllTransactionsScreen Widgets', () {
    testWidgets('InteractiveChartCard renders month/year controls and switches chart modes', (tester) async {
      final now = DateTime.now();
      final sampleTxs = [
        Transaction(title: 'Salary', amount: 3000, date: now, isIncome: true, category: 'Salary'),
        Transaction(title: 'Groceries', amount: 150, date: now, isIncome: false, category: 'Food & Dining'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: InteractiveChartCard(transactions: sampleTxs),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and mode buttons
      expect(find.text('Financial Flow & Analytics'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);

      // Switch to Year Scope
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      // Switch to Bar Chart
      final barButtonFinder = find.byTooltip('Bar Chart');
      expect(barButtonFinder, findsOneWidget);
      await tester.tap(barButtonFinder);
      await tester.pumpAndSettle();

      // Switch to Donut / Pie Breakdown
      final pieButtonFinder = find.byTooltip('Pie / Donut Breakdown');
      expect(pieButtonFinder, findsOneWidget);
      await tester.tap(pieButtonFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('AllTransactionsScreen search dynamically filters transactions and updates chart', (tester) async {
      final now = DateTime.now();
      AppState.transactionsNotifier.value = [
        Transaction(title: 'Grocery Store', amount: 75.0, date: now, isIncome: false, category: 'Food & Dining'),
        Transaction(title: 'Freelance Design', amount: 500.0, date: now, isIncome: true, category: 'Salary'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const AllTransactionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Transactions'), findsOneWidget);

      // Scroll down to see virtualized items in test viewport
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Grocery Store'), findsOneWidget);
      expect(find.text('Freelance Design'), findsOneWidget);

      // Scroll back to top to enter search query
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Grocery');
      await tester.pumpAndSettle();

      // Scroll down to verify filtered list
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // List and chart should now only contain Grocery Store
      expect(find.text('Grocery Store'), findsOneWidget);
      expect(find.text('Freelance Design'), findsNothing);
      expect(find.text('Transactions (1)'), findsOneWidget);
      expect(find.text('Analytics: "Grocery"'), findsOneWidget);
    });

    testWidgets('AccountsScreen switches between Wallets and Loans & Debts segments', (tester) async {
      final now = DateTime.now();
      AppState.accountsNotifier.value = ['Main', 'Savings'];
      AppState.loansNotifier.value = [
        Loan(
          title: 'Concert ticket',
          personName: 'David',
          amount: 60.0,
          dueDate: now.add(const Duration(days: 4)),
          type: 'receivable',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const AccountsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accounts & Wallets'), findsOneWidget);
      expect(find.text('Wallets & Accounts'), findsOneWidget);
      expect(find.text('Loans & Debts'), findsOneWidget);

      // Switch to Loans & Debts segment
      await tester.tap(find.text('Loans & Debts'));
      await tester.pumpAndSettle();

      // Verify Loans dashboard elements
      expect(find.text('Receivable'), findsOneWidget);
      expect(find.text('Payable'), findsOneWidget);
      expect(find.text('David'), findsOneWidget);
      expect(find.text('Concert ticket'), findsOneWidget);
    });
  });
}
