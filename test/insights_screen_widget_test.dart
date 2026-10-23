import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/screens/insights_screen.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/loan.dart';

Finder verticalScroll() => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> scrollTop(WidgetTester tester) async {
  tester.state<ScrollableState>(verticalScroll()).position.jumpTo(0);
  await tester.pumpAndSettle();
}

Future<void> expectVisibleText(WidgetTester tester, String text) async {
  await scrollTop(tester);
  await tester.scrollUntilVisible(
    find.text(text),
    300,
    scrollable: verticalScroll(),
    maxScrolls: 100,
  );
  expect(find.text(text), findsOneWidget);
}

Future<Set<String>> reportHeadings(WidgetTester tester) async {
  const headings = {
    "Executive Accountant's Take",
    'Future Planning: 50/30/20 Rule',
    'Tax Return & Deductions Tracker',
  };
  final found = <String>{};
  await scrollTop(tester);
  for (var step = 0; step < 100; step++) {
    for (final heading in headings) {
      if (find.text(heading).evaluate().isNotEmpty) found.add(heading);
    }
    final position = tester.state<ScrollableState>(verticalScroll()).position;
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo((position.pixels + 300).clamp(0, position.maxScrollExtent));
    await tester.pumpAndSettle();
  }
  await scrollTop(tester);
  return found;
}

void main() {
  setUp(() {
    MonetizationService.isProUnlockedNotifier.value = false;
    AppState.transactionsNotifier.value = [];
    AppState.loansNotifier.value = [];
    AppState.budgetsNotifier.value = {
      'Housing & Rent': 1500.0,
      'Food & Dining': 400.0,
      'Healthcare': 200.0,
    };
    AppState.currencyNotifier.value = '\$';
  });

  testWidgets(
    'InsightsScreen renders Pro locked preview when user is not Pro',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: InsightsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Smart Insights'), findsOneWidget);
      expect(find.text('TALLY PRO EXCLUSIVE'), findsOneWidget);
      expect(find.text('Meet Your Personal Wealth Accountant'), findsOneWidget);
      expect(find.text('Unlock Tally Pro — \$4.99'), findsOneWidget);
    },
  );

  testWidgets(
    'InsightsScreen renders full Personal Wealth Accountant when Pro unlocked',
    (tester) async {
      MonetizationService.isProUnlockedNotifier.value = true;

      final now = DateTime.now();
      AppState.transactionsNotifier.value = [
        Transaction(
          id: 't1',
          title: 'Tech Salary',
          amount: 4500.0,
          date: DateTime(now.year, now.month, 1),
          isIncome: true,
          category: 'Salary',
          account: 'Main',
        ),
        Transaction(
          id: 't2',
          title: 'Monthly Rent',
          amount: 1400.0,
          date: DateTime(now.year, now.month, 2),
          isIncome: false,
          category: 'Housing & Rent',
          account: 'Main',
        ),
        Transaction(
          id: 't3',
          title: 'Grocery Supplies',
          amount: 250.0,
          date: DateTime(now.year, now.month, 3),
          isIncome: false,
          category: 'Food & Dining',
          account: 'Credit Card',
        ),
        Transaction(
          id: 't4',
          title: 'Doctor Visit',
          amount: 80.0,
          date: DateTime(now.year, now.month, 4),
          isIncome: false,
          category: 'Healthcare',
          account: 'Cash',
        ),
      ];

      AppState.loansNotifier.value = [
        Loan(
          id: 'l1',
          title: 'Car Loan',
          personName: 'Auto Finance',
          amount: 1200.0,
          dueDate: now.add(const Duration(days: 10)),
          type: 'payable',
        ),
      ];

      await tester.pumpWidget(const MaterialApp(home: InsightsScreen()));
      await tester.pumpAndSettle();

      // Verify PRO Active badge in AppBar
      await expectVisibleText(tester, 'PRO ACTIVE');

      // Verify Horizon Selector pills
      await expectVisibleText(tester, 'Daily');
      await expectVisibleText(tester, 'Weekly');
      await expectVisibleText(tester, 'Monthly');
      await expectVisibleText(tester, 'Yearly');

      // Verify Executive Accountant Briefing
      await expectVisibleText(tester, "Executive Accountant's Take");

      // Verify Cash Flow Cards
      await expectVisibleText(tester, 'Total Inflow');
      await expectVisibleText(tester, 'Total Outflow');
      await expectVisibleText(tester, 'Net Savings');
      await expectVisibleText(tester, 'Daily Velocity');

      // Verify 50/30/20 Future Planning
      await expectVisibleText(tester, 'Future Planning: 50/30/20 Rule');

      // Verify Loans & Liabilities Portfolio
      await expectVisibleText(tester, 'Loans & Liabilities Portfolio');
      await expectVisibleText(tester, 'Total Debt You Owe');
      await expectVisibleText(tester, '\$1200');

      // Verify Tax Return Tracker
      await expectVisibleText(tester, 'Tax Return & Deductions Tracker');
      await expectVisibleText(tester, 'Total Deductible Expenses');

      // Verify Payment Types Split
      await expectVisibleText(tester, 'Payment Types & Liquidity Split');

      // Switch horizon to Weekly
      await scrollTop(tester);
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Verify period navigator updated
      expect(find.textContaining('This Week'), findsOneWidget);

      // Step period back
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.textContaining('Last Week'), findsOneWidget);
      await expectVisibleText(tester, 'Back to Current');

      // Reset to current
      await tester.tap(find.text('Back to Current'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This Week'), findsOneWidget);
    },
  );

  testWidgets(
    'InsightsScreen segmented domain sub-tabs filter analytical cards',
    (tester) async {
      MonetizationService.isProUnlockedNotifier.value = true;
      final now = DateTime.now();
      AppState.transactionsNotifier.value = [
        Transaction(
          id: 't1',
          title: 'Salary',
          amount: 3000.0,
          date: DateTime(now.year, now.month, 1),
          isIncome: true,
          category: 'Salary',
          account: 'Main',
        ),
      ];
      AppState.loansNotifier.value = [];

      await tester.pumpWidget(const MaterialApp(home: InsightsScreen()));
      await tester.pumpAndSettle();

      const overview = "Executive Accountant's Take";
      const planning = 'Future Planning: 50/30/20 Rule';
      const tax = 'Tax Return & Deductions Tracker';
      expect(await reportHeadings(tester), {overview, planning, tax});
      for (final selection in <String, Set<String>>{
        'Overview': {overview},
        'Budget & Debt': {planning},
        'Tax & Liquidity': {tax},
        'All': {overview, planning, tax},
      }.entries) {
        await tester.tap(find.text(selection.key));
        await tester.pumpAndSettle();
        expect(await reportHeadings(tester), selection.value);
      }
    },
  );
}
