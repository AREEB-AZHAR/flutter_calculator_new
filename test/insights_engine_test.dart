import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/services/insights_engine.dart';

void main() {
  group('InsightsEngine Tests', () {
    final now = DateTime(2026, 10, 2, 12, 0);

    test('Generates comprehensive monthly report with multi-horizon metrics', () {
      final transactions = [
        Transaction(
          id: 't1',
          title: 'Salary',
          amount: 5000.0,
          date: DateTime(2026, 10, 1),
          isIncome: true,
          category: 'Salary',
          account: 'Main',
        ),
        Transaction(
          id: 't2',
          title: 'Apartment Rent',
          amount: 1500.0,
          date: DateTime(2026, 10, 2),
          isIncome: false,
          category: 'Housing & Rent',
          account: 'Main',
        ),
        Transaction(
          id: 't3',
          title: 'Dinner at Steakhouse',
          amount: 200.0,
          date: DateTime(2026, 10, 2),
          isIncome: false,
          category: 'Food & Dining',
          account: 'Credit Card',
        ),
        Transaction(
          id: 't4',
          title: 'Pharmacy Medicine',
          amount: 100.0,
          date: DateTime(2026, 10, 2),
          isIncome: false,
          category: 'Healthcare',
          account: 'Cash',
        ),
      ];

      final loans = [
        Loan(
          id: 'l1',
          title: 'Student Loan',
          personName: 'Federal Aid',
          amount: 2500.0,
          dueDate: DateTime(2026, 10, 15),
          type: 'payable',
        ),
        Loan(
          id: 'l2',
          title: 'Loan to Dave',
          personName: 'Dave',
          amount: 300.0,
          dueDate: DateTime(2026, 11, 1),
          type: 'receivable',
        ),
      ];

      final budgets = {
        'Housing & Rent': 1600.0,
        'Food & Dining': 300.0,
        'Healthcare': 150.0,
      };

      final report = InsightsEngine.generateReport(
        transactions: transactions,
        loans: loans,
        budgets: budgets,
        horizon: TimeHorizon.monthly,
        anchorDate: now,
      );

      expect(report.totalInflow, 5000.0);
      expect(report.totalOutflow, 1800.0);
      expect(report.netSavings, 3200.0);
      expect(report.savingsRate, closeTo(64.0, 0.1));
      expect(report.healthScore.score, greaterThanOrEqualTo(80));
      expect(report.healthScore.rating, anyOf('Excellent', 'Strong'));

      // 50/30/20 Rule
      expect(report.rule503020.needsSpent, 1600.0); // Rent 1500 + Healthcare 100
      expect(report.rule503020.wantsSpent, 200.0); // Food & Dining 200

      // Loans
      expect(report.loanInsight.totalPayable, 2500.0);
      expect(report.loanInsight.totalReceivable, 300.0);
      expect(report.loanInsight.netDebt, 2200.0);
      expect(report.loanInsight.dtiStatus, 'Healthy');

      // Tax
      expect(report.taxInsight.totalDeductible, 100.0); // Healthcare 100
      expect(report.taxInsight.estimatedSavings22Pct, 22.0);

      // Payment Types
      expect(report.paymentTypes.any((p) => p.accountName == 'Main'), isTrue);
      expect(report.paymentTypes.any((p) => p.accountName == 'Credit Card'), isTrue);
      expect(report.paymentTypes.any((p) => p.accountName == 'Cash'), isTrue);
    });

    test('Handles weekly and daily horizons with prorated budgets and safe-to-spend', () {
      final transactions = [
        Transaction(
          id: 't1',
          title: 'Daily Lunch',
          amount: 25.0,
          date: DateTime(2026, 10, 2, 13, 0),
          isIncome: false,
          category: 'Food & Dining',
        ),
      ];

      final dailyReport = InsightsEngine.generateReport(
        transactions: transactions,
        loans: [],
        budgets: {'Food & Dining': 300.0},
        horizon: TimeHorizon.daily,
        anchorDate: now,
      );

      expect(dailyReport.totalOutflow, 25.0);
      // Prorated daily budget = 300 / 30 = 10.0. Spent 25.0 > 10.0 -> isOverBudget = true
      final foodCat = dailyReport.categories.firstWhere((c) => c.category == 'Food & Dining');
      expect(foodCat.isOverBudget, isTrue);

      final weeklyReport = InsightsEngine.generateReport(
        transactions: transactions,
        loans: [],
        budgets: {'Food & Dining': 300.0},
        horizon: TimeHorizon.weekly,
        anchorDate: now,
      );
      expect(weeklyReport.totalOutflow, 25.0);
      // Prorated weekly budget = 300 * 7 / 30 = 70.0. Spent 25.0 < 70.0 -> isOverBudget = false
      final foodCatWeekly = weeklyReport.categories.firstWhere((c) => c.category == 'Food & Dining');
      expect(foodCatWeekly.isOverBudget, isFalse);
    });

    test('Handles zero transactions and zero loans safely without throwing exceptions', () {
      final report = InsightsEngine.generateReport(
        transactions: [],
        loans: [],
        budgets: {},
        horizon: TimeHorizon.yearly,
        anchorDate: now,
      );

      expect(report.totalInflow, 0.0);
      expect(report.totalOutflow, 0.0);
      expect(report.netSavings, 0.0);
      expect(report.savingsRate, 0.0);
      expect(report.dailyVelocity, 0.0);
      expect(report.healthScore.score, greaterThan(0));
      expect(report.accountantSummary.isNotEmpty, isTrue);
    });
  });
}
