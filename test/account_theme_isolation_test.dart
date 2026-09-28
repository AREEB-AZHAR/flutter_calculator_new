import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/models/user_profile.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/models/planned_transaction.dart';
import 'package:balance_tracker/screens/main_nav_screen.dart';
import 'package:balance_tracker/services/tour_service.dart';
import 'package:balance_tracker/services/biometric_service.dart';
import 'package:balance_tracker/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.clearUserSession();
  });

  group('Account Theme Isolation & Entitlement Scoping Tests', () {
    test('User A setting a premium theme does not carry over to User B (free user)', () async {

      // 1. User A logs in, unlocks Pro, and chooses 'Violet Night' (a premium theme)
      await AppState.loadAllUserData('user_alice');
      await MonetizationService.unlockPro();
      expect(MonetizationService.isPro, isTrue);

      await AppState.saveTheme('user_alice', 'Violet Night');
      expect(AppState.themeNameNotifier.value, equals('Violet Night'));

      // 2. User A logs out
      await AppState.clearUserSession();
      expect(AppState.currentUser, isNull);
      expect(AppState.themeNameNotifier.value, equals('Ledger'));
      expect(MonetizationService.isPro, isFalse);

      // 3. User B (new user) logs in
      await AppState.loadAllUserData('user_bob');
      expect(AppState.currentUser, equals('user_bob'));
      expect(MonetizationService.isPro, isFalse);

      // Bob MUST NOT inherit Alice's 'Violet Night' theme
      expect(AppState.themeNameNotifier.value, equals('Ledger'));
      expect(AppState.customPrimaryColorNotifier.value, equals(const Color(0xFFE4572E)));
    });

    test('Existing user with stale premium theme is sanitized to Ledger if not Pro', () async {
      final db = AppDatabase.instance;

      // Simulate Charlie having 'Ocean Blue' saved in database previously while on free tier
      final charlieProfile = UserProfile(
        username: 'user_charlie',
        displayName: 'Charlie',
        theme: 'Ocean Blue',
        primaryColor: const Color(0xFF3B82F6),
        secondaryColor: const Color(0xFF06B6D4),
      );
      await db.saveProfile(charlieProfile);

      // Charlie logs in without Pro
      await AppState.loadAllUserData('user_charlie');
      expect(MonetizationService.isPro, isFalse);

      // Should be automatically sanitized to Ledger
      expect(AppState.themeNameNotifier.value, equals('Ledger'));
      expect(AppState.customPrimaryColorNotifier.value, equals(const Color(0xFFE4572E)));
      expect(AppState.customSecondaryColorNotifier.value, equals(const Color(0xFFF6F0E1)));

      // Database should also be updated with clean Ledger theme
      final updatedProfile = await db.loadProfile('user_charlie');
      expect(updatedProfile.theme, equals('Ledger'));
    });

    test('Pro user retains their chosen premium theme across sessions', () async {
      // Dave is Pro
      await AppState.loadAllUserData('user_dave');
      await MonetizationService.unlockPro();
      await AppState.saveTheme('user_dave', 'Emerald Dark');
      expect(AppState.themeNameNotifier.value, equals('Emerald Dark'));

      // Dave logs out
      await AppState.clearUserSession();
      expect(AppState.themeNameNotifier.value, equals('Ledger'));

      // Dave logs back in: Pro status and theme are restored
      await AppState.loadAllUserData('user_dave');
      expect(MonetizationService.isPro, isTrue);
      expect(AppState.themeNameNotifier.value, equals('Emerald Dark'));
    });
  });

  group('Undo Banner 5-Second Timer Tests', () {
    testWidgets('deleteTransactionWithUndo shows 5-second banner and auto-dismisses', (tester) async {
      AppState.currentUser = null;
      final tx = Transaction(
        id: 'tx_test_1',
        title: 'Grocery Shopping',
        amount: 45.0,
        date: DateTime.now(),
        category: 'Food',
        account: 'Main',
        isIncome: false,
      );
      AppState.transactionsNotifier.value = [tx];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppState.deleteTransactionWithUndo(ctx, tx),
                child: const Text('Delete Tx'),
              ),
            ),
          ),
        ),
      );

      // Tap delete
      await tester.tap(find.text('Delete Tx'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // Verify transaction deleted and Undo banner is visible
      expect(AppState.transactionsNotifier.value, isEmpty);
      expect(find.text('"Grocery Shopping" deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Advance by 5 seconds
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 750));

      // Banner should be dismissed
      expect(find.text('"Grocery Shopping" deleted'), findsNothing);
    });

    testWidgets('deleteGoalWithUndo shows 5-second banner and auto-dismisses', (tester) async {
      AppState.currentUser = null;
      final goal = SavingsGoal(
        id: 'goal_test_1',
        title: 'New Laptop',
        target: 1200.0,
        saved: 300.0,
      );
      AppState.goalsNotifier.value = [goal];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppState.deleteGoalWithUndo(ctx, goal),
                child: const Text('Delete Goal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Goal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(AppState.goalsNotifier.value, isEmpty);
      expect(find.text('Goal "New Laptop" deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Advance by 5 seconds
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Goal "New Laptop" deleted'), findsNothing);
    });
  });

  group('On-Demand Page Lifecycle Tests', () {
    testWidgets('MainNavScreen renders only the active tab on-demand and discards others', (tester) async {
      AppState.currentUser = 'test_user';
      AppState.activeTabNotifier.value = 0; // Dashboard

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavScreen(),
        ),
      );
      await tester.pump();

      // Active screen is DashboardScreen
      expect(find.byKey(const ValueKey('tab_dashboard')), findsOneWidget);
      // Other screens are NOT mounted in the widget tree
      expect(find.byKey(const ValueKey('tab_insights')), findsNothing);
      expect(find.byKey(const ValueKey('tab_goals')), findsNothing);
      expect(find.byKey(const ValueKey('tab_accounts')), findsNothing);
      expect(find.byKey(const ValueKey('tab_profile')), findsNothing);

      // Switch to Insights tab (index 1)
      AppState.activeTabNotifier.value = 1;
      await tester.pump();

      // Now only Insights is mounted; Dashboard is completely discarded
      expect(find.byKey(const ValueKey('tab_dashboard')), findsNothing);
      expect(find.byKey(const ValueKey('tab_insights')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_goals')), findsNothing);

      // Switch to Goals tab (index 2)
      AppState.activeTabNotifier.value = 2;
      await tester.pump();

      expect(find.byKey(const ValueKey('tab_insights')), findsNothing);
      expect(find.byKey(const ValueKey('tab_goals')), findsOneWidget);

      // Switch to Profile tab (index 4)
      AppState.activeTabNotifier.value = 4;
      await tester.pump();

      expect(find.byKey(const ValueKey('tab_goals')), findsNothing);
      expect(find.byKey(const ValueKey('tab_profile')), findsOneWidget);
    });
  });

  group('Cross-User State Isolation & Migration Tests', () {
    test('Tour onboarding state is isolated per user', () async {
      AppState.currentUser = 'user_alice';
      await TourService.markTourCompleted(TourService.tourHome);
      await TourService.markTourCompleted(TourService.tourAccounts);
      expect(await TourService.isTourCompleted(TourService.tourHome), isTrue);
      expect(await TourService.isTourCompleted(TourService.tourAccounts), isTrue);

      // User Bob logs in on same device
      AppState.currentUser = 'user_bob';
      expect(await TourService.isTourCompleted(TourService.tourHome), isFalse);
      expect(await TourService.isTourCompleted(TourService.tourAccounts), isFalse);

      // Alice's completed tours remain intact
      expect(await TourService.isTourCompleted(TourService.tourHome, 'user_alice'), isTrue);
    });

    test('Biometric enrollment is strictly scoped per user and not stolen on login', () async {
      // Alice enables biometrics
      await BiometricService.setBiometricEnabled(true, username: 'user_alice');
      expect(await BiometricService.isBiometricEnabled(username: 'user_alice'), isTrue);
      expect(await BiometricService.getSavedBiometricUser(), equals('user_alice'));

      // Bob logs in without biometrics
      expect(await BiometricService.isBiometricEnabled(username: 'user_bob'), isFalse);

      // Bob explicitly toggles biometrics OFF in his settings
      await BiometricService.setBiometricEnabled(false, username: 'user_bob');
      // Alice's biometric state and saved user are preserved
      expect(await BiometricService.isBiometricEnabled(username: 'user_alice'), isTrue);
      expect(await BiometricService.getSavedBiometricUser(), equals('user_alice'));
    });

    test('Notification reminder preferences are isolated per user', () async {
      // Alice disables reminders
      await NotificationService.instance.setRemindersEnabled(false, 'user_alice');
      expect(await NotificationService.instance.areRemindersEnabled('user_alice'), isFalse);

      // Bob defaults to enabled
      expect(await NotificationService.instance.areRemindersEnabled('user_bob'), isTrue);
    });

    test('Account migration migrates loans and planned transactions and cleans up local user', () async {
      final db = AppDatabase.instance;
      const localUser = 'legacy_charlie';
      const googleUser = 'charlie@gmail.com';

      // Insert test loan and planned transaction for legacy_charlie
      final testLoan = Loan(
        id: 'loan_mig_1',
        title: 'Lent for Dinner',
        personName: 'Bob',
        amount: 50.0,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        type: 'receivable',
      );
      await db.saveLoan(localUser, testLoan);

      final testPlan = PlannedTransaction(
        id: 'plan_mig_1',
        title: 'Gym Membership',
        amount: 30.0,
        date: DateTime.now().add(const Duration(days: 10)),
        category: 'Health',
        account: 'Main',
        isIncome: false,
      );
      await db.savePlannedTransaction(localUser, testPlan);

      // Perform migration to Google account
      await db.migrateAndMergeUserData(
        fromUsername: localUser,
        toUsername: googleUser,
        mergeWithExisting: false,
      );

      // Verify Google user has the loan and planned transaction
      final googleLoans = await db.loadLoans(googleUser);
      expect(googleLoans.any((l) => l.id == 'loan_mig_1'), isTrue);
      final googlePlans = await db.loadPlannedTransactions(googleUser);
      expect(googlePlans.any((p) => p.id == 'plan_mig_1'), isTrue);

      // Verify legacy local user has no orphaned records
      final localLoans = await db.loadLoans(localUser);
      expect(localLoans, isEmpty);
      final localPlans = await db.loadPlannedTransactions(localUser);
      expect(localPlans, isEmpty);
    });
  });
}
