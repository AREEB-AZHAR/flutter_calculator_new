import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/services/ledger_view_cache.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/language_service.dart';
import 'package:balance_tracker/services/app_version.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/screens/all_transactions_screen.dart';
import 'package:balance_tracker/screens/accounts_screen.dart';
import 'package:balance_tracker/screens/profile_screen.dart';
import 'package:balance_tracker/widgets/transaction_tile.dart';
import 'package:balance_tracker/widgets/interactive_chart_card.dart';

class CountedRows<T> extends ListBase<T> {
  final List<T> rows;
  int reads = 0;
  CountedRows(this.rows);
  @override
  int get length => rows.length;
  @override
  set length(int value) => throw UnsupportedError('immutable fixture');
  @override
  T operator [](int index) {
    reads++;
    return rows[index];
  }

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('immutable fixture');
}

Transaction tx(int i, {double amount = 1}) => Transaction(
  id: '$i',
  title: i.isEven ? 'Salary $i' : 'Coffee $i',
  amount: amount,
  date: DateTime.now(),
  isIncome: i.isEven,
  category: i.isEven ? 'Salary' : 'Food & Dining',
  account: i.isEven ? 'Main' : 'Cash',
);

Finder verticalIn(String key) => find
    .descendant(
      of: find.byKey(PageStorageKey(key)),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    )
    .first;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'tally_tour_accounts_completed': true});
    AppState.currentUser = null;
    AppState.transactionsNotifier.value = [];
    AppState.accountsNotifier.value = ['Main', 'Cash'];
    AppState.loansNotifier.value = [];
    AppState.currencyNotifier.value = r'$';
    MonetizationService.resetToLoggedOut();
  });
  tearDown(() {
    AppState.transactionsNotifier.value = [];
    AppState.loansNotifier.value = [];
    AppState.currencyNotifier.value = r'$';
  });

  test(
    '100k rows: wallet and spending cache hits do not read ledger again',
    () {
      final rows = CountedRows(List.generate(100000, tx));
      final wallets = WalletViewCache();
      final spending = SpendingViewCache();
      final wallet = wallets.get(rows);
      final summary = spending.get(rows);
      expect(wallet.overallBalance, 0);
      expect(wallet.overallSpending, 50000);
      expect(wallet.balances['Main'], 50000);
      expect(wallet.balances['Cash'], -50000);
      expect(wallet.forAccount('Cash').length, 50000);
      expect(wallet.forAccount('missing'), isEmpty);
      expect(identical(wallet.forAccount(null), rows), true);
      expect(summary.income, 50000);
      expect(summary.expense, 50000);
      expect(summary.essential, 50000);
      expect(summary.discretionary, 0);
      expect(summary.topCategories.single.value, 50000);
      final reads = rows.reads;
      for (var i = 0; i < 100; i++) {
        expect(identical(wallets.get(rows), wallet), true);
        expect(identical(spending.get(rows), summary), true);
      }
      expect(rows.reads, reads);
      final replacement = [tx(1, amount: 17)];
      expect(wallets.get(replacement).overallBalance, -17);
      expect(spending.get(replacement).largestExpense, 17);
      expect(spending.get([]).largestExpenseTitle, 'None');
    },
  );

  test(
    'search caches case-insensitive filters and invalidates edited snapshots',
    () {
      final source = CountedRows(List.generate(100000, tx));
      final cache = TransactionFilterCache();
      expect(identical(cache.get(source), source), true);
      expect(source.reads, 0);
      final result = cache.get(source, filter: 'Expense', query: 'food');
      expect(result.length, 50000);
      final reads = source.reads;
      expect(
        identical(cache.get(source, filter: 'Expense', query: 'FOOD'), result),
        true,
      );
      expect(source.reads, reads);
      expect(cache.get(source, filter: 'Income', query: 'main').length, 50000);
      expect(cache.get(source, query: 'no match'), isEmpty);
      expect(cache.get([tx(1, amount: 9)], query: 'coffee').single.amount, 9);
    },
  );

  test('loan views reuse grouped rows and refresh after settlement', () {
    final source = CountedRows([
      Loan(
        id: 'r',
        title: 'Owed',
        personName: 'A',
        amount: 10,
        dueDate: DateTime(2099),
        type: 'receivable',
      ),
      Loan(
        id: 'p',
        title: 'Debt',
        personName: 'B',
        amount: 7,
        dueDate: DateTime(2099),
        type: 'payable',
      ),
      Loan(
        id: 's',
        title: 'Paid',
        personName: 'C',
        amount: 100,
        dueDate: DateTime(2099),
        type: 'payable',
        isSettled: true,
      ),
    ]);
    final cache = LoanViewCache();
    final view = cache.get(source);
    expect(view.receivables, 10);
    expect(view.payables, 7);
    expect(view.filtered('all').length, 3);
    expect(view.filtered('settled').single.id, 's');
    final reads = source.reads;
    for (final filter in ['all', 'payable', 'receivable', 'settled']) {
      expect(cache.get(source).filtered(filter), isNotEmpty);
    }
    expect(source.reads, reads);
    expect(cache.get([source[0].copyWith(isSettled: true)]).receivables, 0);
  });

  testWidgets(
    'transaction search debounces, clears pending query, and survives header eviction',
    (tester) async {
      AppState.transactionsNotifier.value = List.generate(1000, tx);
      await tester.pumpWidget(const MaterialApp(home: AllTransactionsScreen()));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('transaction_search'));
      await tester.enterText(field, 'Salary');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<InteractiveChartCard>(find.byType(InteractiveChartCard))
            .transactions
            .length,
        1000,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<InteractiveChartCard>(find.byType(InteractiveChartCard))
            .transactions
            .length,
        500,
      );
      final position = tester
          .state<ScrollableState>(verticalIn('transactions_scroll'))
          .position;
      position.jumpTo(5000);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionTile).evaluate().length, lessThan(30));
      position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'Salary');
      await tester.enterText(field, 'Coffee');
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.widget<TextField>(field).controller!.text, '');
      expect(
        tester
            .widget<InteractiveChartCard>(find.byType(InteractiveChartCard))
            .transactions
            .length,
        1000,
      );
      await tester.enterText(field, 'disposed');
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wallet switch selects indexed rows and refreshes changed ledger',
    (tester) async {
      AppState.transactionsNotifier.value = List.generate(1000, tx);
      await tester.pumpWidget(const MaterialApp(home: AccountsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Main').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveChartCard>(find.byType(InteractiveChartCard))
            .transactions
            .length,
        500,
      );
      AppState.transactionsNotifier.value = [tx(0, amount: 99)];
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveChartCard>(find.byType(InteractiveChartCard))
            .transactions
            .single
            .amount,
        99,
      );
    },
  );

  testWidgets('Profile lazy sections and draggable settings remain reachable', (
    tester,
  ) async {
    AppState.transactionsNotifier.value = List.generate(1000, tx);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    expect(find.text(LanguageService.tr('open_settings')), findsNothing);
    await tester.scrollUntilVisible(find.text(r'+$500'), 300,
      scrollable: verticalIn('profile_scroll'), maxScrolls: 30);
    AppState.currencyNotifier.value = '€';
    await tester.pumpAndSettle();
    expect(find.text('+€500'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(LanguageService.tr('open_settings')),
      300,
      scrollable: verticalIn('profile_scroll'),
      maxScrolls: 30,
    );
    await tester.tap(find.text(LanguageService.tr('open_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cloud & Data'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppVersion.displayString),
      300,
      scrollable: verticalIn('profile_settings_scroll'),
      maxScrolls: 30,
    );
    expect(find.text(AppVersion.displayString), findsOneWidget);
    tester
        .state<ScrollableState>(verticalIn('profile_settings_scroll'))
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE & IDENTITY'), findsOneWidget);
  });
}
