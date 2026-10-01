import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/models/goal_entry.dart';

void main() {
  group('SavingsGoal & Savings Vault Pacing Engine Tests', () {
    test('Calculates days remaining and daily/weekly required pacing correctly', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 10));

      final goal = SavingsGoal(
        id: 'g1',
        title: 'New Laptop',
        target: 1000.0,
        saved: 200.0, // $800 left to save in 10 days
        dueDate: targetDate,
        periodType: 'custom',
      );

      expect(goal.daysRemaining, inInclusiveRange(9, 10));
      expect(goal.dailySavingsNeeded, closeTo(80.0, 5.0)); // ~$80/day
      expect(goal.weeklySavingsNeeded, closeTo(560.0, 35.0)); // ~$560/week
      expect(goal.isExpired, isFalse);
      expect(goal.isCompleted, isFalse);
    });

    test('Daily allowance goal calculates target correctly', () {
      final now = DateTime.now();
      final todayGoal = SavingsGoal(
        id: 'g_daily',
        title: 'Daily Coffee Reserve',
        target: 100.0,
        saved: 25.0,
        dueDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
        periodType: 'daily',
        isRecurring: true,
        recurrence: 'daily',
      );

      expect(todayGoal.periodType, 'daily');
      expect(todayGoal.isRecurring, isTrue);
      expect(todayGoal.recurrence, 'daily');
      expect(todayGoal.remainingToSave, 75.0);
      expect(todayGoal.daysRemaining, inInclusiveRange(0, 1));
    });

    test('Expired goal is detected when dueDate is in the past and goal is not met', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final expiredGoal = SavingsGoal(
        id: 'g_past',
        title: 'Old Goal',
        target: 500.0,
        saved: 100.0,
        dueDate: pastDate,
      );

      expect(expiredGoal.isExpired, isTrue);
      expect(expiredGoal.isCompleted, isFalse);
    });

    test('Completed goal is detected when saved >= target', () {
      final completedGoal = SavingsGoal(
        id: 'g_done',
        title: 'Flight Ticket',
        target: 600.0,
        saved: 650.0,
        isCompleted: true,
      );

      expect(completedGoal.isCompleted, isTrue);
      expect(completedGoal.progress, 1.0);
      expect(completedGoal.remainingToSave, 0.0);
    });

    test('GoalEntry serialization and deserialization retains precision and note', () {
      final entryDate = DateTime(2026, 10, 2, 14, 30);
      final entry = GoalEntry(
        id: 'entry_1',
        goalId: 'g_laptop',
        amount: 150.50,
        date: entryDate,
        note: 'Freelance design gig bonus',
      );

      final json = entry.toJson();
      final reconstructed = GoalEntry.fromJson(json);

      expect(reconstructed.id, 'entry_1');
      expect(reconstructed.goalId, 'g_laptop');
      expect(reconstructed.amount, 150.50);
      expect(reconstructed.note, 'Freelance design gig bonus');
      expect(reconstructed.date.year, 2026);
      expect(reconstructed.date.month, 10);
      expect(reconstructed.date.day, 2);
    });

    test('SavingsGoal with nested GoalEntries serializes and restores fully', () {
      final entries = [
        GoalEntry(
          id: 'e1',
          goalId: 'g_multi',
          amount: 50.0,
          date: DateTime(2026, 10, 1),
          note: 'Initial deposit',
        ),
        GoalEntry(
          id: 'e2',
          goalId: 'g_multi',
          amount: 75.0,
          date: DateTime(2026, 10, 2),
          note: 'Weekly top-up',
        ),
      ];

      final goal = SavingsGoal(
        id: 'g_multi',
        title: 'Gaming Console',
        target: 500.0,
        saved: 125.0,
        dueDate: DateTime(2026, 11, 15),
        periodType: 'monthly',
        isRecurring: true,
        recurrence: 'monthly',
        entries: entries,
      );

      final json = goal.toJson();
      final restored = SavingsGoal.fromJson(json);

      expect(restored.id, 'g_multi');
      expect(restored.title, 'Gaming Console');
      expect(restored.saved, 125.0);
      expect(restored.entries.length, 2);
      expect(restored.entries[0].amount, 50.0);
      expect(restored.entries[1].amount, 75.0);
      expect(restored.isRecurring, isTrue);
      expect(restored.recurrence, 'monthly');
    });

    test('Soft-deletion preservation rule checks', () {
      // Rule: goals with >10% progress or completed must be soft-deleted (isArchived=true)
      final goal15Pct = SavingsGoal(
        id: 'g_preserve',
        title: 'Preserve Me',
        target: 1000.0,
        saved: 150.0, // 15% progress
      );

      final shouldArchive1 = goal15Pct.isCompleted || goal15Pct.progress >= 0.10;
      expect(shouldArchive1, isTrue);

      final goal5Pct = SavingsGoal(
        id: 'g_discard',
        title: 'Discard Me',
        target: 1000.0,
        saved: 40.0, // 4% progress
      );

      final shouldArchive2 = goal5Pct.isCompleted || goal5Pct.progress >= 0.10;
      expect(shouldArchive2, isFalse);
    });
  });
}
