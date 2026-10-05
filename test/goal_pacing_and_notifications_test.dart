import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/models/goal_entry.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/screens/goals_screen.dart';
import 'package:balance_tracker/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SavingsGoal Calculations & Pacing Tests', () {
    test('remainingToSave reflects actual remaining amount rather than total target', () {
      final goal = SavingsGoal(
        title: 'Vacation',
        target: 500,
        saved: 0,
        dueDate: DateTime.now().add(const Duration(days: 10)),
      );

      expect(goal.remainingToSave, 500.0);
      expect(goal.dailySavingsNeeded, closeTo(50.0, 0.1));

      // After user makes a deposit of 200
      goal.saved = 200;
      expect(goal.remainingToSave, 300.0); // Exactly what user has left, not 500
      expect(goal.dailySavingsNeeded, closeTo(30.0, 0.1)); // Live updated daily savings rate
    });

    test('dailySavingsNeeded recalculates dynamically as deposits increase', () {
      final goal = SavingsGoal(
        title: 'Emergency Fund',
        target: 1000,
        saved: 0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
      );

      expect(goal.dailySavingsNeeded, closeTo(200.0, 0.1));

      // Add a deposit of 500
      goal.saved = 500;
      expect(goal.remainingToSave, 500.0);
      expect(goal.dailySavingsNeeded, closeTo(100.0, 0.1));

      // Add another deposit of 400
      goal.saved = 900;
      expect(goal.remainingToSave, 100.0);
      expect(goal.dailySavingsNeeded, closeTo(20.0, 0.1));

      // Reach target
      goal.saved = 1000;
      expect(goal.remainingToSave, 0.0);
      expect(goal.dailySavingsNeeded, 0.0);
    });

    test('isExpired does NOT prematurely expire on the due date during the day', () {
      final today = DateTime.now();
      // Goal due today at noon
      final goalDueToday = SavingsGoal(
        title: 'Daily Task',
        target: 50,
        saved: 10,
        dueDate: DateTime(today.year, today.month, today.day, 12, 0, 0),
      );

      // Should NOT be expired today because the day is not over yet (expires after 23:59:59)
      expect(goalDueToday.isExpired, isFalse);
      expect(goalDueToday.isActive, isTrue);
      expect(goalDueToday.isDueToday, isTrue);
      expect(goalDueToday.daysRemaining, 1);
      expect(goalDueToday.dailySavingsNeeded, 40.0);
    });

    test('goals without explicit dueDate compute effective days and daily savings rate', () {
      final monthlyGoal = SavingsGoal(
        title: 'Monthly Savings',
        target: 300,
        saved: 0,
        dueDate: null, // No explicit due date
        periodType: 'monthly',
      );

      expect(monthlyGoal.effectiveDueDate, isNotNull);
      expect(monthlyGoal.daysRemaining, greaterThan(0));
      expect(monthlyGoal.dailySavingsNeeded, greaterThan(0.0));
      expect(monthlyGoal.isActive, isTrue);

      final dailyGoal = SavingsGoal(
        title: 'Daily Stash',
        target: 20,
        saved: 5,
        dueDate: null,
        periodType: 'daily',
      );
      expect(dailyGoal.daysRemaining, 1);
      expect(dailyGoal.remainingToSave, 15.0);
      expect(dailyGoal.dailySavingsNeeded, 15.0);
    });
  });

  group('GoalsScreen Widget UI Tests', () {
    testWidgets('GoalsScreen displays amount left badge and pacing badge for active goals with transactions', (tester) async {
      final testGoal = SavingsGoal(
        id: 'test_goal_1',
        title: 'MacBook Pro',
        target: 2000,
        saved: 500,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        entries: [
          GoalEntry(
            id: 'entry_1',
            goalId: 'test_goal_1',
            amount: 500,
            date: DateTime.now(),
            note: 'Initial deposit',
          ),
        ],
      );

      AppState.goalsNotifier.value = [testGoal];
      AppState.currencyNotifier.value = '\$';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const GoalsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('MacBook Pro'), findsOneWidget);
      // Check saved and target
      expect(find.text('\$500'), findsWidgets);
      expect(find.text('of \$2000'), findsOneWidget);
      // Check prominent "Amount Left" badge
      expect(find.text('\$1500 left'), findsOneWidget);
      // Check pacing badge appears despite having transactions
      expect(find.textContaining('Save \$150/day'), findsOneWidget);
      expect(find.textContaining('10d left'), findsOneWidget);
    });
  });

  group('NotificationService Deterministic ID & Pacing Copy Tests', () {
    test('stableHash produces deterministic, non-negative 32-bit values', () {
      final id1 = NotificationService.stableHash('goal_emergency_fund');
      final id2 = NotificationService.stableHash('goal_emergency_fund');
      final idOther = NotificationService.stableHash('goal_vacation');

      expect(id1, equals(id2), reason: 'stableHash must return identical results for identical strings');
      expect(id1, greaterThanOrEqualTo(0));
      expect(id1, lessThanOrEqualTo(0x7fffffff));
      expect(id1, isNot(equals(idOther)), reason: 'Distinct strings should yield different hashes');

      // Test slot IDs differ by slot offset
      final slot0 = NotificationService.getGoalNotificationId('goal_test', 0);
      final slot1 = NotificationService.getGoalNotificationId('goal_test', 1);
      expect(slot1 - slot0, equals(1));
    });

    test('formatGoalReminderContent uses days remaining instead of calendar due date for multi-day goals', () {
      final goal = SavingsGoal(
        title: 'New Car',
        target: 1000,
        saved: 200, // 800 left
        dueDate: DateTime.now().add(const Duration(days: 4)),
      );

      final content = NotificationService.formatGoalReminderContent(
        goal: goal,
        currencySymbol: '\$',
      );

      expect(content.title, '🎯 Goal Pacing: New Car');
      expect(content.body, contains('\$800 left to reach "New Car"'));
      expect(content.body, contains('Save \$200/day'));
      expect(content.body, contains('(4 days remaining)!'));
      // Ensure calendar dates like month names or "finish by" do not appear
      expect(content.body, isNot(contains('finish by')));
      expect(content.body, isNot(contains('Jan')));
      expect(content.body, isNot(contains('Dec')));
    });

    test('formatGoalReminderContent formats due today or 1 day remaining with urgency text', () {
      final todayGoal = SavingsGoal(
        title: 'Rent Stash',
        target: 500,
        saved: 450, // 50 left
        dueDate: DateTime.now(), // Due today
      );

      final content = NotificationService.formatGoalReminderContent(
        goal: todayGoal,
        currencySymbol: '€',
      );

      expect(content.title, '🎯 Today\'s Goal: Rent Stash');
      expect(content.body, contains('You have €50 left to save for "Rent Stash" (1 day remaining · Due today)!'));
    });

    test('formatGoalReminderContent handles daily periodType accurately', () {
      final dailyGoal = SavingsGoal(
        title: 'Daily Lunch',
        target: 25,
        saved: 10,
        dueDate: null,
        periodType: 'daily',
      );

      final content = NotificationService.formatGoalReminderContent(
        goal: dailyGoal,
        currencySymbol: '£',
      );

      expect(content.title, '🎯 Today\'s Goal: Daily Lunch');
      expect(content.body, contains('You have £15 left to save for "Daily Lunch" (1 day remaining · Due today)!'));
    });
  });
}
