import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/models/goal_entry.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/models/transaction.dart' as model;
import 'package:balance_tracker/models/user_profile.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/services/display_rate_service.dart';
import 'package:balance_tracker/services/ledger_sync.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/purchase_backend.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/widgets/testing_performance_settings.dart';
import 'package:balance_tracker/widgets/goal_manager_dialog.dart';

class GoalRemote implements LedgerRemote {
  LedgerRecords records = {'transactions': {}, 'goals': {}};
  @override
  Future<LedgerRecords> read() async => records;
  @override
  Future<void> commit(List<LedgerWrite> writes) async {
    for (final write in writes) {
      records[write.collection]![write.id] = Map.of(write.data);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const user = 'repair@example.test';
  final db = AppDatabase.instance;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'legacy_prefs_migrated': true});
    MonetizationService.testingVipNotifier.value = false;
    MonetizationService.resetToLoggedOut();
    PurchaseSecurityPolicy.developmentOverride = null;
    MonetizationService.refreshForTesting = null;
    AppState.currentUser = user;
    final sqlite = await db.database;
    for (final table in [
      'goal_entries',
      'goals',
      'transactions',
      'ledger_outbox',
    ]) {
      await sqlite.delete(table);
    }
  });
  tearDown(() {
    MonetizationService.testingVipNotifier.value = false;
    MonetizationService.resetToLoggedOut();
    MonetizationService.refreshForTesting = null;
    PurchaseSecurityPolicy.developmentOverride = null;
    AppState.currentUser = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DisplayRateService.channel, null);
  });

  test(
    'FREEVIP hides ads, survives initialization and can be disabled',
    () async {
      // Even with production grants disabled, this exception is debug-only.
      PurchaseSecurityPolicy.developmentOverride = false;
      expect(MonetizationService.testingVipCodeEnabled, isTrue);
      expect(
        await MonetizationService.redeemPromoCode(' freevip '),
        contains('not a store purchase'),
      );
      expect(MonetizationService.isPro, isTrue);
      expect(MonetizationService.isAdFree, isTrue);
      MonetizationService.resetToLoggedOut();
      await MonetizationService.loadUserEntitlements(user);
      expect(MonetizationService.isAdFree, isTrue);
      await MonetizationService.disableTestingVip();
      expect(MonetizationService.testingVipActive, isFalse);
      expect(MonetizationService.isAdFree, isFalse);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'tally_testing_freevip',
        ),
        isFalse,
      );
    },
  );

  test(
    'local profile loads while verification is pending and preserves saved paid palette',
    () async {
      PurchaseSecurityPolicy.developmentOverride = false;
      final pending = Completer<void>();
      MonetizationService.refreshForTesting = () => pending.future;
      await db.saveProfile(
        UserProfile(
          username: user,
          displayName: 'Ready locally',
          theme: 'Emerald Dark',
          primaryColor: Colors.green,
        ),
      );
      await AppState.loadAllUserData(user).timeout(const Duration(seconds: 5));
      expect(pending.isCompleted, isFalse);
      expect(AppState.displayNameNotifier.value, 'Ready locally');
      expect(MonetizationService.isPro, isFalse);
      expect(AppState.themeNameNotifier.value, 'Ledger');
      expect((await db.loadProfile(user)).theme, 'Emerald Dark');
      pending.complete();
      await MonetizationService.verificationReady;
    },
  );

  test('delayed palette work cannot publish into another account', () async {
    PurchaseSecurityPolicy.developmentOverride = false;
    final pending = Completer<void>();
    MonetizationService.refreshForTesting = () => pending.future;
    await AppState.loadAllUserData(user);
    AppState.currentUser = 'another';
    AppState.themeNameNotifier.value = 'Paper';
    pending.complete();
    await MonetizationService.verificationReady;
    await Future<void>.delayed(Duration.zero);
    expect(AppState.themeNameNotifier.value, 'Paper');
  });

  test(
    'archived goals load with scoped entries; removal survives restart and sync',
    () async {
      final goal = SavingsGoal(id: 'ghost', title: 'Hidden goal', target: 100);
      await db.upsertGoal(user, goal);
      await db.addGoalEntry(
        user,
        GoalEntry(
          id: 'deposit',
          goalId: goal.id,
          amount: 40,
          date: DateTime(2026, 10, 24),
        ),
      );
      await db.softDeleteGoal(user, goal.id);
      await db.upsertGoal(
        'other',
        SavingsGoal(id: 'other-goal', title: 'Other', target: 20),
      );
      await db.saveTransactions(user, [
        model.Transaction(
          id: 'kept',
          title: 'Deposit ledger',
          amount: 40,
          date: DateTime(2026, 10, 24),
          isIncome: false,
        ),
      ]);
      expect(await db.loadGoals(user), isEmpty);
      final archived = await db.loadGoals(user, includeArchived: true);
      expect(archived.single.id, 'ghost');
      expect(archived.single.entries.single.amount, 40);
      final remote = GoalRemote();
      var store = SqliteLedgerStore(await db.database);
      await LedgerSyncEngine(store, remote, checkSession: () {}).sync(user);
      expect(remote.records['goals']!['ghost']!['isArchived'], isTrue);
      // Attempt to remove another user's record must do nothing.
      await db.permanentlyDeleteGoal(user, 'other-goal');
      expect((await db.loadGoals('other')).single.title, 'Other');
      await db.permanentlyDeleteGoal(user, goal.id);
      expect(await db.loadGoalEntries(user, goal.id), isEmpty);
      expect((await db.loadTransactions(user)).single.id, 'kept');
      await db.close();
      store = SqliteLedgerStore(await db.database);
      final snapshot = await store.snapshot(user);
      expect(snapshot.pending.single.data['_deleted'], isTrue);
      await LedgerSyncEngine(store, remote, checkSession: () {}).sync(user);
      await LedgerSyncEngine(store, remote, checkSession: () {}).sync(user);
      expect(remote.records['goals']!['ghost']!['_deleted'], isTrue);
      expect(await db.loadGoals(user, includeArchived: true), isEmpty);
    },
  );

  test(
    'goal deletion rolls back entry and goal changes together on failure',
    () async {
      await db.upsertGoal(
        user,
        SavingsGoal(id: 'rollback', title: 'Keep', target: 100),
      );
      await db.addGoalEntry(
        user,
        GoalEntry(
          id: 'entry',
          goalId: 'rollback',
          amount: 10,
          date: DateTime.now(),
        ),
      );
      final sqlite = await db.database;
      await sqlite.execute(
        "CREATE TRIGGER reject_goal_delete BEFORE DELETE ON goals BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      try {
        await expectLater(
          db.permanentlyDeleteGoal(user, 'rollback'),
          throwsA(anything),
        );
        expect(await db.loadGoalEntries(user, 'rollback'), hasLength(1));
        expect(await db.loadGoals(user), hasLength(1));
      } finally {
        await sqlite.execute('DROP TRIGGER reject_goal_delete');
      }
    },
  );

  test(
    '60 and 120 Hz requests persist; unsupported rate falls back safely',
    () async {
      var rates = [60, 120];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DisplayRateService.channel, (call) async {
            expect(call.method, 'setPreference');
            final hz = (call.arguments as Map)['hz'];
            return {
              'accepted': hz == 0 || rates.contains(hz),
              'supported': rates,
            };
          });
      await DisplayRateService.instance.setPreference(60);
      expect(DisplayRateService.preference.value, 60);
      await DisplayRateService.instance.setPreference(120);
      expect(
        (await SharedPreferences.getInstance()).getInt('tally_display_rate'),
        120,
      );
      rates = [60];
      await DisplayRateService.instance.setPreference(120);
      expect(DisplayRateService.preference.value, 0);
      expect(DisplayRateService.status.value, contains('unavailable'));
      await expectLater(
        DisplayRateService.instance.setPreference(90),
        throwsArgumentError,
      );
    },
  );

  test('platforms without the display plugin use system control', () async {
    await DisplayRateService.instance.setPreference(120);
    expect(DisplayRateService.preference.value, 0);
    expect(DisplayRateService.supported.value, isEmpty);
  });

  testWidgets(
    'settings disables unsupported 120 Hz and enables debug testing controls',
    (tester) async {
      DisplayRateService.supported.value = [60];
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TestingPerformanceSettings())),
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '120 Hz'))
            .onSelected,
        isNull,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '60 Hz'))
            .onSelected,
        isNotNull,
      );
      expect(find.text('Enter testing code'), findsOneWidget);
    },
  );

  testWidgets(
    'manager exposes an archived goal and requires confirmation to remove it',
    (tester) async {
      await tester.runAsync(() async {
        await db.upsertGoal(
          user,
          SavingsGoal(
            id: 'hidden-ui',
            title: 'Archived UI goal',
            target: 100,
            isArchived: true,
          ),
        );
      });
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GoalManagerDialog())),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Archived UI goal'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Remove goal permanently'));
      });
      await tester.pumpAndSettle();
      expect(find.text('Remove goal permanently?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Archived UI goal'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Remove goal permanently'));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Remove goal'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Archived UI goal'), findsNothing);
      expect(find.text('No goals on this device.'), findsOneWidget);
    },
  );
}
