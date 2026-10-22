import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState.currentUser = 'GoalTestUser';
    AppState.goalsNotifier.value = [];
  });

  group('Goal Notification Timezone & Cleanup Tests', () {
    test('configureLocalTimeZone sets tz.local to device timezone offset instead of UTC', () {
      NotificationService.configureLocalTimeZone();
      final deviceOffset = DateTime.now().timeZoneOffset;
      final localOffset = tz.local.currentTimeZone.offset;
      expect(localOffset, equals(deviceOffset));
    });

    test('scheduleGoalReminders with empty goals purges tracked goal IDs', () async {
      final service = NotificationService.instance;

      // Simulate a previously scheduled goal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('tally_scheduled_goal_ids', ['old_goal_123', 'old_goal_456']);

      // Call scheduleGoalReminders with an empty list (user has no active goals)
      await service.scheduleGoalReminders([], '\$');

      // Tracked goal IDs must be completely cleared
      final updatedTracked = prefs.getStringList('tally_scheduled_goal_ids') ?? [];
      expect(updatedTracked, isEmpty);
    });

    test('scheduleGoalReminders cleans up IDs of deleted goals while retaining active ones', () async {
      final service = NotificationService.instance;
      final prefs = await SharedPreferences.getInstance();

      // Simulate 2 previously scheduled goals
      await prefs.setStringList('tally_scheduled_goal_ids', ['active_goal_1', 'deleted_goal_2']);

      final activeGoal = SavingsGoal(
        id: 'active_goal_1',
        title: 'New Laptop',
        target: 1000,
        saved: 200,
        dueDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Reschedule with only the active goal
      await service.scheduleGoalReminders([activeGoal], '\$');

      final updatedTracked = prefs.getStringList('tally_scheduled_goal_ids') ?? [];
      expect(updatedTracked, contains('active_goal_1'));
      expect(updatedTracked, isNot(contains('deleted_goal_2')));
    });

    test('cancelGoalReminders removes target goal from persistent tracked list', () async {
      final service = NotificationService.instance;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList('tally_scheduled_goal_ids', ['goal_to_remove', 'goal_to_keep']);

      await service.cancelGoalReminders('goal_to_remove');

      final updatedTracked = prefs.getStringList('tally_scheduled_goal_ids') ?? [];
      expect(updatedTracked, isNot(contains('goal_to_remove')));
      expect(updatedTracked, contains('goal_to_keep'));
    });

    test('cancelAllGoalReminders empties tracked list', () async {
      final service = NotificationService.instance;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList('tally_scheduled_goal_ids', ['g1', 'g2', 'g3']);

      await service.cancelAllGoalReminders();

      final updatedTracked = prefs.getStringList('tally_scheduled_goal_ids') ?? [];
      expect(updatedTracked, isEmpty);
    });

    test('Daily friendly messages exclude goal references when no active goals exist', () {
      AppState.goalsNotifier.value = [];

      final hasActiveGoals = AppState.goalsNotifier.value.any((g) => g.isActive && g.remainingToSave > 0);
      expect(hasActiveGoals, isFalse);

      final availableMessages = hasActiveGoals
          ? NotificationService.friendlyMessages
          : NotificationService.friendlyMessages
              .where((m) => !m.toLowerCase().contains('goal') && !m.contains('🎯'))
              .toList();

      for (final msg in availableMessages) {
        expect(msg.toLowerCase().contains('goal'), isFalse);
        expect(msg.contains('🎯'), isFalse);
      }
    });

    test('Daily friendly messages include goal references when active goals exist', () {
      final activeGoal = SavingsGoal(
        id: 'my_goal',
        title: 'Emergency Fund',
        target: 500,
        saved: 50,
      );
      AppState.goalsNotifier.value = [activeGoal];

      final hasActiveGoals = AppState.goalsNotifier.value.any((g) => g.isActive && g.remainingToSave > 0);
      expect(hasActiveGoals, isTrue);

      final availableMessages = hasActiveGoals
          ? NotificationService.friendlyMessages
          : NotificationService.friendlyMessages
              .where((m) => !m.toLowerCase().contains('goal') && !m.contains('🎯'))
              .toList();

      expect(availableMessages.any((m) => m.contains('🎯')), isTrue);
    });
  });
}
