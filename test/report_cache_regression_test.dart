import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/services/insights_engine.dart';
import 'package:balance_tracker/services/insights_report_cache.dart';
import 'package:balance_tracker/services/ledger_view_cache.dart';

class ReadCountedLedger extends ListBase<Transaction> {
  final List<Transaction> source;
  int reads = 0;
  ReadCountedLedger(this.source);
  @override
  int get length => source.length;
  @override
  set length(int value) => throw UnsupportedError('immutable');
  @override
  Transaction operator [](int index) {
    reads++;
    return source[index];
  }

  @override
  void operator []=(int index, Transaction value) =>
      throw UnsupportedError('immutable');
}

void main() {
  final now = DateTime(2026, 10, 24);
  Transaction tx(
    String id,
    double amount, {
    bool income = false,
    String category = 'Food & Dining',
  }) => Transaction(
    id: id,
    title: id,
    amount: amount,
    date: now,
    isIncome: income,
    category: category,
  );

  test(
    'Insights cache hits read zero rows and invalidate all report inputs',
    () {
      final cache = InsightsReportCache();
      var transactions = ReadCountedLedger(
        List.generate(10000, (i) => tx('$i', 1)),
      );
      List<Loan> loans = [];
      Map<String, double> budgets = {'Food & Dining': 100};
      List<SavingsGoal> goals = [];
      var horizon = TimeHorizon.monthly;
      var offset = 0;
      var currency = r'$';
      var date = now;
      InsightsReport report() => cache.get(
        transactions: transactions,
        loans: loans,
        budgets: budgets,
        goals: goals,
        horizon: horizon,
        periodOffset: offset,
        currency: currency,
        now: date,
      );
      var previous = report();
      final reads = transactions.reads;
      for (var i = 0; i < 100; i++) {
        expect(identical(report(), previous), isTrue);
      }
      expect(transactions.reads, reads);
      for (final change in <void Function()>[
        () => budgets = {...budgets, 'Food & Dining': 200},
        () => loans = [...loans],
        () => goals = [...goals],
        () => horizon = TimeHorizon.weekly,
        () => offset = -1,
        () => currency = '€',
        () => date = date.add(const Duration(days: 1)),
        () => transactions = ReadCountedLedger([tx('replacement', 10)]),
      ]) {
        change();
        final next = report();
        expect(identical(next, previous), isFalse);
        expect(identical(report(), next), isTrue);
        previous = next;
      }
    },
  );

  test(
    'Dashboard balance excludes outgoing goal transfers and reuses snapshots',
    () {
      final cache = LiquidBalanceCache();
      final rows = ReadCountedLedger([
        tx('salary', 100, income: true),
        tx('expense', 20),
        tx('goal', 40, category: 'Savings Goal'),
        tx('returned', 5, income: true, category: 'Savings Goal'),
      ]);
      expect(cache.get(rows), 85);
      final reads = rows.reads;
      for (var i = 0; i < 100; i++) {
        expect(cache.get(rows), 85);
      }
      expect(rows.reads, reads);
      expect(cache.get([tx('new', 7)]), -7);
      expect(cache.get([]), 0);
    },
  );
}
