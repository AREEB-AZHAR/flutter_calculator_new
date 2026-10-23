import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/services/chart_summary.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/screens/goals_screen.dart';
import 'package:balance_tracker/widgets/lazy_section_list.dart';
import 'package:balance_tracker/widgets/interactive_chart_card.dart';
import 'package:balance_tracker/widgets/custom_painters.dart';
import 'package:balance_tracker/widgets/ad_banner_widget.dart';

class CountingLedger extends ListBase<Transaction> {
  final List<Transaction> rows;
  int reads = 0;
  CountingLedger(this.rows);
  @override
  int get length => rows.length;
  @override
  set length(int value) => throw UnsupportedError('immutable fixture');
  @override
  Transaction operator [](int index) {
    reads++;
    return rows[index];
  }

  @override
  void operator []=(int index, Transaction value) =>
      throw UnsupportedError('immutable fixture');
}

void main() {
  testWidgets('ad section preserves its instance across offscreen scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazySectionList(
            sections: [
              (_) => const AdBannerWidget(),
              ...List.generate(
                30,
                (i) =>
                    (_) => const SizedBox(height: 200),
              ),
            ],
          ),
        ),
      ),
    );
    final original = tester.state(find.byType(AdBannerWidget));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(3000);
    await tester.pumpAndSettle();
    expect(original.mounted, true);
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(
      identical(tester.state(find.byType(AdBannerWidget)), original),
      true,
    );
  });
  test(
    '100k ledger summary reuses unchanged snapshot without reading rows',
    () {
      final source = CountingLedger(
        List.generate(
          100000,
          (i) => Transaction(
            id: '$i',
            title: 'Sample',
            amount: 1,
            date: DateTime(2026, 10, 1),
            isIncome: i.isEven,
            account: i.isEven ? 'Cash' : 'Bank',
          ),
        ),
      );
      final cache = ChartSummaryCache();
      final summary = cache.get(source, year: 2026, month: 10);
      expect(summary.income, 50000);
      expect(summary.expense, 50000);
      final initialReads = source.reads;
      for (var i = 0; i < 100; i++) {
        expect(
          identical(cache.get(source, year: 2026, month: 10), summary),
          true,
        );
      }
      expect(source.reads, initialReads);
      expect(
        cache.get(source, year: 2026, month: 10, account: 'Cash').expense,
        0,
      );
      expect(cache.get(source, year: 2025).transactions, isEmpty);
      expect(cache.get(source, year: 2026, month: 9).transactions, isEmpty);
      final changed = [
        Transaction(
          id: 'changed',
          title: 'Updated',
          amount: 7,
          date: DateTime(2026, 10, 1),
          isIncome: false,
        ),
      ];
      expect(cache.get(changed, year: 2026, month: 10).expense, 7);
    },
  );

  testWidgets('1000 sections mount only near viewport and remain reachable', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazySectionList(
            sections: List.generate(
              1000,
              (i) => (_) {
                builds++;
                return SizedBox(height: 100, child: Text('Section $i'));
              },
            ),
          ),
        ),
      ),
    );
    expect(builds, lessThan(20));
    expect(find.text('Section 999'), findsNothing);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(5000);
    await tester.pumpAndSettle();
    expect(find.text('Section 50'), findsOneWidget);
    expect(builds, lessThan(100));
    expect(find.textContaining('Section ').evaluate().length, lessThan(20));
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Section 0'), findsOneWidget);
  });

  testWidgets('chart selection survives lazy eviction and rebuild', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazySectionList(
            sections: [
              (_) => const InteractiveChartCard(transactions: []),
              ...List.generate(
                30,
                (i) =>
                    (_) => SizedBox(height: 200, child: Text('$i')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.pie_chart_outline));
    await tester.pumpAndSettle();
    Finder donut() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DonutChartPainter,
    );
    expect(donut(), findsOneWidget);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(3000);
    await tester.pumpAndSettle();
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(donut(), findsOneWidget);
  });

  testWidgets(
    'large goal list creates only nearby cards and reaches final goal',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(() => AppState.goalsNotifier.value = []);
      AppState.goalsNotifier.value = List.generate(
        500,
        (i) => SavingsGoal(
          id: '$i',
          title: 'Goal $i',
          target: 100,
          dueDate: DateTime(2099),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: GoalsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Goal 499'), findsNothing);
      expect(
        find
            .byWidgetPredicate(
              (w) => w.key?.toString().contains('goal_') ?? false,
            )
            .evaluate()
            .length,
        lessThan(10),
      );
      await tester.scrollUntilVisible(
        find.text('Goal 499'),
        10000,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 100,
      );
      expect(find.text('Goal 499'), findsOneWidget);
    },
  );
}
