import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:balance_tracker/main.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/screens/main_nav_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState.currentUser = 'benchmark_user';
    AppState.transactionsNotifier.value = [
      Transaction(
        id: 'tx_1',
        title: 'Salary Deposit',
        amount: 5000.0,
        date: DateTime.now(),
        isIncome: true,
        category: 'Salary',
        account: 'Main',
      ),
      Transaction(
        id: 'tx_2',
        title: 'Organic Groceries',
        amount: 142.50,
        date: DateTime.now(),
        isIncome: false,
        category: 'Food & Dining',
        account: 'Main',
      ),
      Transaction(
        id: 'tx_3',
        title: 'Electric Utility',
        amount: 85.00,
        date: DateTime.now(),
        isIncome: false,
        category: 'Utilities',
        account: 'Main',
      ),
    ];
    AppState.budgetsNotifier.value = {
      'Food & Dining': 500.0,
      'Utilities': 200.0,
      'Housing & Rent': 1500.0,
    };
    AppState.activeTabNotifier.value = 0;
  });

  testWidgets('Smoothness Test: Splash Screen multi-stage animation 60fps frames', (WidgetTester tester) async {
    final frameTimes = <int>[];

    await tester.pumpWidget(const TallyApp());

    // Pump 60 frames across the 2700ms animation (each step ~45ms simulated)
    for (int i = 0; i < 60; i++) {
      final sw = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 45));
      sw.stop();
      frameTimes.add(sw.elapsedMicroseconds);
    }

    final maxMicros = frameTimes.reduce((a, b) => a > b ? a : b);
    final avgMicros = frameTimes.reduce((a, b) => a + b) / frameTimes.length;

    debugPrint('📊 Splash Animation Performance:');
    debugPrint('   Average frame build: ${(avgMicros / 1000).toStringAsFixed(2)} ms');
    debugPrint('   Peak frame build: ${(maxMicros / 1000).toStringAsFixed(2)} ms');

    // Peak frame should comfortably stay below headless test budget and average below 16ms
    expect(avgMicros / 1000, lessThan(16.67));
    expect(maxMicros / 1000, lessThan(250.0));
  });

  testWidgets('Smoothness Test: MainNavScreen and Dashboard initial mount & slide animation', (WidgetTester tester) async {
    final frameTimes = <int>[];

    final swMount = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const MainNavScreen(),
      ),
    );
    swMount.stop();

    debugPrint('📊 MainNavScreen Initial Mount: ${(swMount.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Pump frames across the 800ms card slide transition
    for (int i = 0; i < 16; i++) {
      final sw = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 50));
      sw.stop();
      frameTimes.add(sw.elapsedMicroseconds);
    }

    final maxMicros = frameTimes.reduce((a, b) => a > b ? a : b);
    final avgMicros = frameTimes.reduce((a, b) => a + b) / frameTimes.length;

    debugPrint('📊 Dashboard Slide Animation Performance:');
    debugPrint('   Average frame build: ${(avgMicros / 1000).toStringAsFixed(2)} ms');
    debugPrint('   Peak frame build: ${(maxMicros / 1000).toStringAsFixed(2)} ms');

    expect(maxMicros / 1000, lessThan(80.0));
  });

  testWidgets('Smoothness Test: Tab switching transitions between all 5 screens', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const MainNavScreen(),
      ),
    );
    await tester.pump();

    final tabSwitchTimes = <String, double>{};

    for (int tabIndex = 1; tabIndex <= 4; tabIndex++) {
      final sw = Stopwatch()..start();
      AppState.activeTabNotifier.value = tabIndex;
      await tester.pump();
      sw.stop();

      final tabNames = ['Home', 'Insights', 'Goals', 'Accounts', 'Profile'];
      tabSwitchTimes[tabNames[tabIndex]] = sw.elapsedMicroseconds / 1000.0;
    }

    // Switch back to Home
    final swHome = Stopwatch()..start();
    AppState.activeTabNotifier.value = 0;
    await tester.pump();
    swHome.stop();
    tabSwitchTimes['Return to Home'] = swHome.elapsedMicroseconds / 1000.0;

    debugPrint('📊 Tab Switching Durations:');
    tabSwitchTimes.forEach((tab, duration) {
      debugPrint('   Tab switch to $tab: ${duration.toStringAsFixed(2)} ms');
      expect(duration, lessThan(400.0));
    });
  });

  testWidgets('Smoothness Test: Chart Line Flow vs Donut toggle', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Locate Donut icon toggle
    final donutToggleFinder = find.byIcon(Icons.pie_chart_outline);
    if (donutToggleFinder.evaluate().isNotEmpty) {
      final swDonut = Stopwatch()..start();
      await tester.tap(donutToggleFinder);
      await tester.pump();
      swDonut.stop();

      debugPrint('📊 Chart Toggle to Donut: ${(swDonut.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      expect(swDonut.elapsedMicroseconds / 1000.0, lessThan(200.0));

      final lineToggleFinder = find.byIcon(Icons.show_chart);
      final swLine = Stopwatch()..start();
      await tester.tap(lineToggleFinder);
      await tester.pump();
      swLine.stop();

      debugPrint('📊 Chart Toggle to Line Flow: ${(swLine.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      expect(swLine.elapsedMicroseconds / 1000.0, lessThan(200.0));
    }
  });

  testWidgets('Smoothness Test: Route transition to MainNavScreen frame timing', (WidgetTester tester) async {
    final frameTimes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const MainNavScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 250),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Go'));
    await tester.pump();

    // Pump 10 frames across the 250ms transition
    for (int i = 0; i < 10; i++) {
      final sw = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 25));
      sw.stop();
      frameTimes.add(sw.elapsedMicroseconds);
    }

    final maxMicros = frameTimes.reduce((a, b) => a > b ? a : b);
    final avgMicros = frameTimes.reduce((a, b) => a + b) / frameTimes.length;

    debugPrint('📊 Route Transition to MainNavScreen Frame Performance:');
    debugPrint('   Average frame build: ${(avgMicros / 1000).toStringAsFixed(2)} ms');
    debugPrint('   Peak frame build: ${(maxMicros / 1000).toStringAsFixed(2)} ms');

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(maxMicros / 1000, lessThan(150.0));
  });
}
