import '../models/transaction.dart';

/// Aggregates an immutable ledger snapshot for one chart period and account.
class ChartSummary {
  final List<Transaction> transactions;
  final double income;
  final double expense;
  final Map<String, double> incomeCategories;
  final Map<String, double> spendCategories;
  ChartSummary._(
    List<Transaction> transactions,
    this.income,
    this.expense,
    Map<String, double> incomeCategories,
    Map<String, double> spendCategories,
  ) : transactions = List.unmodifiable(transactions),
      incomeCategories = Map.unmodifiable(incomeCategories),
      spendCategories = Map.unmodifiable(spendCategories);
}

/// One entry per chart. AppState publishes a new list on every ledger mutation;
/// switching visual controls/currency/theme can reuse the same summary in O(1).
class ChartSummaryCache {
  List<Transaction>? _source;
  int? _year;
  int? _month;
  String? _account;
  ChartSummary? _summary;

  ChartSummary get(
    List<Transaction> source, {
    required int year,
    int? month,
    String? account,
  }) {
    if (identical(source, _source) &&
        year == _year &&
        month == _month &&
        account == _account &&
        _summary != null) {
      return _summary!;
    }
    final selected = <Transaction>[];
    var income = 0.0;
    var expense = 0.0;
    final incomeCategories = <String, double>{};
    final spendCategories = <String, double>{};
    for (final tx in source) {
      if (tx.date.year != year ||
          (month != null && tx.date.month != month) ||
          (account != null && tx.account != account)) {
        continue;
      }
      selected.add(tx);
      final categories = tx.isIncome ? incomeCategories : spendCategories;
      categories.update(
        tx.category,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    _source = source;
    _year = year;
    _month = month;
    _account = account;
    return _summary = ChartSummary._(
      selected,
      income,
      expense,
      incomeCategories,
      spendCategories,
    );
  }
}
