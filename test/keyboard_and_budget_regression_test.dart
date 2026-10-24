import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/screens/dashboard_screen.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/language_service.dart';
import 'package:balance_tracker/utils/constants.dart';
import 'package:balance_tracker/widgets/keyboard_stable_page.dart';
import 'package:balance_tracker/widgets/form_dialog.dart';
import 'package:balance_tracker/widgets/transaction_dialog.dart';

class PageProbe extends StatelessWidget {
  final VoidCallback onBuild;
  const PageProbe({super.key, required this.onBuild});
  @override
  Widget build(BuildContext context) {
    onBuild();
    final media = MediaQuery.of(context);
    return Text('page:${media.viewInsets.bottom}:${media.padding.bottom}');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'tally_tour_home_completed': true});
    DashboardScreen.hasAnimatedIntro = true;
    AppState.currentUser = null;
    AppState.transactionsNotifier.value = [];
    AppState.goalsNotifier.value = [];
    AppState.accountsNotifier.value = ['Main'];
    AppState.budgetsNotifier.value = {'Food & Dining': 500};
    MonetizationService.testingVipNotifier.value = false;
    MonetizationService.resetToLoggedOut();
  });

  Future<void> openBudget(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'budget category defaults to an available item and adds without changing selection',
    (tester) async {
      await openBudget(tester);
      expect(tester.takeException(), isNull);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.initialValue, isNot('Food & Dining'));
      expect(dropdown.initialValue, isNotNull);
      await tester.enterText(find.byType(TextField), '75');
      await tester.tap(find.text(LanguageService.tr('add')).last);
      await tester.pumpAndSettle();
      expect(AppState.budgetsNotifier.value[dropdown.initialValue], 75);
      expect(AppState.budgetsNotifier.value['Food & Dining'], 500);
    },
  );

  testWidgets(
    'all categories budgeted shows a message instead of constructing invalid dropdown',
    (tester) async {
      AppState.budgetsNotifier.value = {
        for (final key in categoryIcons.keys) key: 100,
      };
      await openBudget(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(
        find.text('All categories already have a budget.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keyboard insets do not rebuild tab content; root dialogs retain keyboard insets',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetViewInsets);
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardStablePage(
            child: Scaffold(
              body: Column(
                children: [
                  PageProbe(onBuild: () => builds++),
                  Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => FormDialog(
                          title: Text(
                            'editor:${MediaQuery.viewInsetsOf(context).bottom}',
                          ),
                          content: const TextField(),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Open editor'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      final before = builds;
      for (final height in [100.0, 200.0, 300.0, 0.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: height);
        await tester.pumpAndSettle();
        expect(find.text('editor:$height'), findsOneWidget);
        expect(find.text('page:0.0:24.0'), findsOneWidget);
        expect(builds, before);
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpAndSettle();
      expect(
        builds,
        greaterThan(before),
        reason: 'Real size changes must still propagate.',
      );
    },
  );

  testWidgets(
    'transaction form remains scrollable above keyboard on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTransactionDialog(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(find.byType(FormDialog), findsOneWidget);
      expect(find.byType(IntrinsicWidth), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(LanguageService.tr('cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(FormDialog), findsNothing);
    },
  );
  testWidgets(
    'promo form fits a narrow phone with keyboard and cancels safely',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    MonetizationService.showPromoCodeDialog(context),
                child: const Text('Open promo'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open promo'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(find.byType(FormDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(FormDialog), findsNothing);
      expect(MonetizationService.testingVipActive, isFalse);
    },
  );
}
