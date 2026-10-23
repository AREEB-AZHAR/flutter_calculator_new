import '../models/transaction.dart';
import '../models/loan.dart';

/// Per-screen caches. AppState publishes a new list on every ledger mutation;
/// published lists and transaction fields must not be mutated in place.
class WalletView {
  final List<Transaction> all;
  final Map<String, List<Transaction>> accounts;
  final Map<String, double> balances;
  final Map<String, double> spending;
  final double overallBalance;
  final double overallSpending;
  WalletView._(
    this.all,
    this.accounts,
    this.balances,
    this.spending,
    this.overallBalance,
    this.overallSpending,
  );
  List<Transaction> forAccount(String? account) =>
      account == null ? all : accounts[account] ?? const [];
}

class WalletViewCache {
  List<Transaction>? _source;
  WalletView? _value;
  WalletView get(List<Transaction> source) {
    if (identical(source, _source) && _value != null) return _value!;
    final accounts = <String, List<Transaction>>{};
    final balances = <String, double>{};
    final spending = <String, double>{};
    var income = 0.0;
    var spent = 0.0;
    for (final tx in source) {
      accounts.putIfAbsent(tx.account, () => []).add(tx);
      final change = tx.isIncome ? tx.amount : -tx.amount;
      if (tx.isIncome) income += tx.amount;
      balances.update(
        tx.account,
        (value) => value + change,
        ifAbsent: () => change,
      );
      if (!tx.isIncome) {
        spent += tx.amount;
        spending.update(
          tx.account,
          (value) => value + tx.amount,
          ifAbsent: () => tx.amount,
        );
      }
    }
    _source = source;
    return _value = WalletView._(
      source,
      Map.unmodifiable(
        accounts.map(
          (key, rows) => MapEntry(key, List<Transaction>.unmodifiable(rows)),
        ),
      ),
      Map.unmodifiable(balances),
      Map.unmodifiable(spending),
      income - spent,
      spent,
    );
  }
}

class TransactionFilterCache {
  List<Transaction>? _source;
  String? _filter;
  String? _query;
  List<Transaction>? _value;
  List<Transaction> get(
    List<Transaction> source, {
    String filter = 'All',
    String query = '',
  }) {
    final normalized = query.toLowerCase();
    if (identical(source, _source) &&
        filter == _filter &&
        normalized == _query &&
        _value != null) {
      return _value!;
    }
    _source = source;
    _filter = filter;
    _query = normalized;
    if (filter == 'All' && normalized.isEmpty) return _value = source;
    return _value = List.unmodifiable(
      source.where((tx) {
        if (filter == 'Income' && !tx.isIncome ||
            filter == 'Expense' && tx.isIncome) {
          return false;
        }
        return normalized.isEmpty ||
            tx.title.toLowerCase().contains(normalized) ||
            tx.category.toLowerCase().contains(normalized) ||
            tx.account.toLowerCase().contains(normalized);
      }),
    );
  }
}

class SpendingView {
  final double income, expense, essential, discretionary, largestExpense;
  final String largestExpenseTitle;
  final List<MapEntry<String, double>> topCategories;
  SpendingView._(
    this.income,
    this.expense,
    this.essential,
    this.discretionary,
    this.largestExpense,
    this.largestExpenseTitle,
    this.topCategories,
  );
}

class SpendingViewCache {
  List<Transaction>? _source;
  SpendingView? _value;
  SpendingView get(List<Transaction> source) {
    if (identical(source, _source) && _value != null) return _value!;
    const needs = {
      'Housing & Rent',
      'Food & Dining',
      'Utilities',
      'Healthcare',
      'Transportation',
      'Education',
    };
    var income = 0.0,
        expense = 0.0,
        essential = 0.0,
        discretionary = 0.0,
        largest = 0.0;
    var title = 'None';
    final categories = <String, double>{};
    for (final tx in source) {
      if (tx.isIncome) {
        income += tx.amount;
        continue;
      }
      expense += tx.amount;
      categories.update(
        tx.category,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
      if (tx.amount > largest) {
        largest = tx.amount;
        title = '${tx.title} (${tx.category})';
      }
      if (needs.contains(tx.category)) {
        essential += tx.amount;
      } else {
        discretionary += tx.amount;
      }
    }
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _source = source;
    return _value = SpendingView._(
      income,
      expense,
      essential,
      discretionary,
      largest,
      title,
      List.unmodifiable(sorted.take(4)),
    );
  }
}

class LoanView {
  final double receivables, payables;
  final List<Loan> all, receivable, payable, settled;
  LoanView._(
    this.receivables,
    this.payables,
    this.all,
    this.receivable,
    this.payable,
    this.settled,
  );
  List<Loan> filtered(String filter) => switch (filter) {
    'receivable' => receivable,
    'payable' => payable,
    'settled' => settled,
    _ => all,
  };
}

class LoanViewCache {
  List<Loan>? _source;
  LoanView? _value;
  LoanView get(List<Loan> source) {
    if (identical(source, _source) && _value != null) return _value!;
    var receivables = 0.0, payables = 0.0;
    final receivable = <Loan>[], payable = <Loan>[], settled = <Loan>[];
    for (final loan in source) {
      if (loan.isSettled) {
        settled.add(loan);
      } else {
        if (loan.isReceivable) {
          receivables += loan.amount;
          receivable.add(loan);
        } else {
          payables += loan.amount;
          if (loan.isPayable) payable.add(loan);
        }
      }
    }
    _source = source;
    return _value = LoanView._(
      receivables,
      payables,
      source,
      List.unmodifiable(receivable),
      List.unmodifiable(payable),
      List.unmodifiable(settled),
    );
  }
}

/// Dashboard liquid balance excludes outgoing goal transfers, matching the
/// existing balance semantics without rescanning on unrelated UI rebuilds.
class LiquidBalanceCache {
  List<Transaction>? _source;
  double _balance = 0;
  double get(List<Transaction> transactions) {
    if (identical(transactions, _source)) return _balance;
    _source = transactions;
    return _balance = transactions.fold(0.0, (sum, item) {
      if (item.category == 'Savings Goal' && !item.isIncome) return sum;
      return sum + (item.isIncome ? item.amount : -item.amount);
    });
  }
}
