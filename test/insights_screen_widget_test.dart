import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/screens/insights_screen.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/loan.dart';

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

  testWidgets('InsightsScreen renders Pro locked preview when user is not Pro', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InsightsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart Insights'), findsOneWidget);
    expect(find.text('TALLY PRO EXCLUSIVE'), findsOneWidget);
    expect(find.text('Meet Your Personal Wealth Accountant'), findsOneWidget);
    expect(find.text('Unlock Tally Pro — \$4.99'), findsOneWidget);
  });

  testWidgets('InsightsScreen renders full Personal Wealth Accountant when Pro unlocked', (tester) async {
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

    await tester.pumpWidget(
      const MaterialApp(
        home: InsightsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify PRO Active badge in AppBar
    expect(find.text('PRO ACTIVE'), findsOneWidget);

    // Verify Horizon Selector pills
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);

    // Verify Executive Accountant Briefing
    expect(find.text("Executive Accountant's Take"), findsOneWidget);

    // Verify Cash Flow Cards
    expect(find.text('Total Inflow'), findsOneWidget);
    expect(find.text('Total Outflow'), findsOneWidget);
    expect(find.text('Net Savings'), findsOneWidget);
    expect(find.text('Daily Velocity'), findsOneWidget);

    // Verify 50/30/20 Future Planning
    expect(find.text('Future Planning: 50/30/20 Rule'), findsOneWidget);

    // Verify Loans & Liabilities Portfolio
    expect(find.text('Loans & Liabilities Portfolio'), findsOneWidget);
    expect(find.text('Total Debt You Owe'), findsOneWidget);
    expect(find.text('\$1200'), findsOneWidget);

    // Verify Tax Return Tracker
    expect(find.text('Tax Return & Deductions Tracker'), findsOneWidget);
    expect(find.text('Total Deductible Expenses'), findsOneWidget);

    // Verify Payment Types Split
    expect(find.text('Payment Types & Liquidity Split'), findsOneWidget);

    // Switch horizon to Weekly
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    // Verify period navigator updated
    expect(find.textContaining('This Week'), findsOneWidget);

    // Step period back
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.textContaining('Last Week'), findsOneWidget);
    expect(find.text('Back to Current'), findsOneWidget);

    // Reset to current
    await tester.tap(find.text('Back to Current'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This Week'), findsOneWidget);
  });
}
