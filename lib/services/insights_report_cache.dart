import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/savings_goal.dart';
import 'insights_engine.dart';

/// AppState publishes replacement collections on mutations. Compare snapshots
/// without hashing every row or newly allocated MapEntry objects on rebuilds.
class InsightsReportCache {
  List<Transaction>? _transactions;
  List<Loan>? _loans;
  Map<String, double>? _budgets;
  List<SavingsGoal>? _goals;
  TimeHorizon? _horizon;
  int? _offset;
  String? _currency;
  DateTime? _day;
  InsightsReport? _report;

  InsightsReport get({
    required List<Transaction> transactions,
    required List<Loan> loans,
    required Map<String, double> budgets,
    required List<SavingsGoal> goals,
    required TimeHorizon horizon,
    required int periodOffset,
    required String currency,
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    if (_report != null &&
        identical(transactions, _transactions) &&
        identical(loans, _loans) &&
        identical(budgets, _budgets) &&
        identical(goals, _goals) &&
        _horizon == horizon &&
        _offset == periodOffset &&
        _currency == currency &&
        _day == day) {
      return _report!;
    }
    _transactions = transactions;
    _loans = loans;
    _budgets = budgets;
    _goals = goals;
    _horizon = horizon;
    _offset = periodOffset;
    _currency = currency;
    _day = day;
    return _report = InsightsEngine.generateReport(
      transactions: transactions,
      loans: loans,
      budgets: budgets,
      goals: goals,
      horizon: horizon,
      periodOffset: periodOffset,
      currency: currency,
      anchorDate: date,
    );
  }
}
