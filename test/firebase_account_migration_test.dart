import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/firebase_account_service.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/widgets/password_recovery_dialog.dart';
import 'package:balance_tracker/models/transaction.dart' as model;
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/models/goal_entry.dart';
import 'package:balance_tracker/models/loan.dart';
import 'package:balance_tracker/models/planned_transaction.dart';
import 'helpers/fake_account_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.instance;
  late FakeAccountBackend backend;
  late FirebaseAccountService service;
  const email = 'alice@example.test';
  const old = 'LegacySecret!123';
  const cloud = 'FirebaseSecret!456';
  Future<void> legacy({String? boundEmail = email}) async {
    await db.registerUser(username: 'Alice', email: boundEmail, password: old);
    await db.insertTransaction(
      'Alice',
      model.Transaction(
        id: 'kept-tx',
        title: 'Keep this',
        amount: 17.5,
        date: DateTime(2026, 10, 26),
        isIncome: false,
        category: 'Food',
        account: 'Custom wallet',
      ),
    );
    await db.saveAccounts('Alice', ['Custom wallet']);
    await db.saveBudgets('Alice', {'Food': 99});
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({'legacy_prefs_migrated': true});
    AppState.currentUser = null;
    final sql = await db.database;
    for (final table in [
      'users',
      'profiles',
      'accounts',
      'budgets',
      'transactions',
      'goals',
      'goal_entries',
      'loans',
      'planned_transactions',
      'ledger_outbox',
      'ledger_sync_baselines',
    ]) {
      await sql.delete(table);
    }
    backend = FakeAccountBackend();
    service = FirebaseAccountService(backend: backend, database: db);
  });

  test(
    'legacy migration waits for verified email and preserves vault key, records and preferences',
    () async {
      await legacy();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tally_biometric_enabled_Alice', true);
      final before = await db.getUserByEmail('Alice');
      await expectLater(
        service.signIn('Alice', old),
        throwsA(isA<FirebaseEmailVerificationRequired>()),
      );
      expect(backend.creates, 1);
      expect(backend.verifications, 1);
      expect(await db.firebaseIdentity('Alice'), isNull);
      expect(
        (await db.getUserByEmail('Alice'))!['password_hash'],
        before!['password_hash'],
      );
      backend.seed(email, old, uid: 'new-$email');
      expect(await service.signIn('Alice', old), 'Alice');
      expect(
        (await db.firebaseIdentity('Alice'))!['firebase_uid'],
        'new-$email',
      );
      expect((await db.loadTransactions('Alice')).single.id, 'kept-tx');
      expect(await db.loadAccounts('Alice'), ['Custom wallet']);
      expect(await db.loadBudgets('Alice'), {'Food': 99});
      expect(prefs.getBool('tally_biometric_enabled_Alice'), true);
      final migrated = await db.getUserByEmail('Alice');
      expect(migrated!['password_hash'], 'FIREBASE_AUTH_ONLY');
      expect(migrated['salt'], '');
      expect(await db.authenticateUser('Alice', old), false);
    },
  );

  test(
    'different cloud/local passwords require both proofs without changing Firebase password',
    () async {
      await legacy();
      backend.seed(email, cloud);
      await expectLater(
        service.signIn('Alice', cloud),
        throwsA(isA<LocalVaultProofRequired>()),
      );
      expect(await db.firebaseIdentity('Alice'), isNull);
      expect(
        await service.signIn('Alice', cloud, legacyPassword: old),
        'Alice',
      );
      expect(backend.passwords[email], cloud);
      expect(backend.creates, 0);
    },
  );

  test('local password cannot overwrite an existing cloud account', () async {
    await legacy();
    backend.seed(email, cloud);
    await expectLater(service.signIn('Alice', old), throwsStateError);
    expect(backend.passwords[email], cloud);
    expect(await db.firebaseIdentity('Alice'), isNull);
    expect(await db.authenticateUser('Alice', old), true);
  });

  test(
    'a short legacy password can migrate to a new strong Firebase password',
    () async {
      await db.registerUser(username: 'Alice', email: email, password: '1234');
      backend.enforceMinimumPassword = true;
      await expectLater(
        service.signIn('Alice', '1234'),
        throwsA(isA<MigrationPasswordRequired>()),
      );
      expect(await db.authenticateUser('Alice', '1234'), true);
      await expectLater(
        service.signIn('Alice', '1234', migrationPassword: cloud),
        throwsA(isA<FirebaseEmailVerificationRequired>()),
      );
      backend.seed(email, cloud, uid: 'new-$email');
      expect(
        await service.signIn('Alice', cloud, legacyPassword: '1234'),
        'Alice',
      );
      expect(backend.passwords[email], cloud);
      expect(await db.authenticateUser('Alice', '1234'), false);
    },
  );

  test(
    'migration preserves all financial tables, outbox revisions and local profile exactly',
    () async {
      await legacy();
      final date = DateTime(2026, 10, 26);
      await db.saveGoals('Alice', [
        SavingsGoal(
          id: 'goal',
          title: 'Keep goal',
          target: 100,
          createdAt: date,
        ),
      ]);
      await db.addGoalEntry(
        'Alice',
        GoalEntry(
          id: 'entry',
          goalId: 'goal',
          amount: 12,
          date: date,
          createdAt: date,
        ),
      );
      await db.saveLoan(
        'Alice',
        Loan(
          id: 'loan',
          title: 'Keep loan',
          personName: 'Friend',
          amount: 20,
          dueDate: date,
          type: 'receivable',
          createdAt: date,
        ),
      );
      await db.savePlannedTransaction(
        'Alice',
        PlannedTransaction(
          id: 'plan',
          title: 'Keep schedule',
          amount: 7,
          date: date,
          isIncome: false,
          recurrence: 'Monthly',
          createdAt: date,
        ),
      );
      final profile = await db.loadProfile('Alice');
      await db.saveProfile(
        profile.copyWith(
          displayName: 'Custom name',
          bio: 'Custom bio',
          currency: 'PKR',
        ),
      );
      final sql = await db.database;
      const tables = [
        'transactions',
        'goals',
        'goal_entries',
        'loans',
        'planned_transactions',
        'profiles',
        'accounts',
        'budgets',
        'ledger_outbox',
        'ledger_sync_baselines',
      ];
      final before = {
        for (final table in tables) table: await sql.query(table),
      };
      backend.seed(email, old);
      await service.signIn('Alice', old);
      for (final table in tables) {
        expect(
          await sql.query(table),
          before[table],
          reason: '$table must not change during identity attachment',
        );
      }
    },
  );

  test(
    'ambiguous username/email is rejected rather than selecting the first vault',
    () async {
      await legacy();
      await db.registerUser(
        username: email,
        password: cloud,
        email: 'other@example.test',
      );
      backend.seed(email, old);
      await expectLater(service.signIn(email, old), throwsStateError);
      expect(await db.firebaseIdentity('Alice'), isNull);
      expect(backend.current, isNull);
    },
  );

  test('failed identity transaction rolls back credential changes', () async {
    await legacy();
    final before = await db.getUserByEmail('Alice');
    var checks = 0;
    await expectLater(
      db.attachFirebaseIdentity(
        username: 'Alice',
        uid: 'uid-alice',
        email: email,
        provider: 'password',
        expectedLegacyHash: before!['password_hash'] as String,
        checkSession: () {
          if (++checks > 1) throw StateError('account changed');
        },
      ),
      throwsStateError,
    );
    expect(await db.firebaseIdentity('Alice'), isNull);
    expect(await db.getUserByEmail('Alice'), before);
  });

  test(
    'wrong local and Firebase credentials never create an account',
    () async {
      await legacy();
      await expectLater(
        service.signIn('Alice', 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(backend.creates, 0);
      expect(await db.firebaseIdentity('Alice'), isNull);
    },
  );

  test('offline sign-in cannot fall back to the old local hash', () async {
    await legacy();
    backend.seed(email, old);
    await service.signIn('Alice', old);
    backend.offline = true;
    await expectLater(
      service.signIn('Alice', old),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(await db.authenticateUser('Alice', old), false);
    expect((await db.loadTransactions('Alice')).single.id, 'kept-tx');
  });

  test(
    'mapping persists across reopen and rejects a changed Firebase UID',
    () async {
      await legacy();
      backend.seed(email, old);
      await service.signIn('Alice', old);
      await db.close();
      expect(await db.firebaseUsernameForUid('uid-alice'), 'Alice');
      backend.seed(email, old, uid: 'different-uid');
      await expectLater(service.signIn('Alice', old), throwsStateError);
      expect((await db.loadTransactions('Alice')).single.id, 'kept-tx');
    },
  );

  test(
    'changed local credentials during authentication abort migration',
    () async {
      await legacy();
      backend.seed(email, old);
      backend.afterSignIn = () async {
        await db.changePassword('Alice', old, cloud);
      };
      await expectLater(service.signIn('Alice', old), throwsStateError);
      expect(await db.firebaseIdentity('Alice'), isNull);
      expect(await db.authenticateUser('Alice', cloud), true);
    },
  );

  test(
    'account replacement during authentication cannot attach returned credentials',
    () async {
      await legacy();
      backend.seed(email, old);
      backend.afterSignIn = () async {
        backend.current = const FirebaseAccount(
          'bob',
          'bob@example.test',
          true,
          {'password'},
        );
      };
      await expectLater(service.signIn('Alice', old), throwsStateError);
      expect(await db.firebaseIdentity('Alice'), isNull);
    },
  );

  test(
    'email-less legacy account is retained until explicit email migration',
    () async {
      await legacy(boundEmail: null);
      await expectLater(
        service.signIn('Alice', old),
        throwsA(isA<MigrationEmailRequired>()),
      );
      backend.seed(email, old);
      expect(
        await service.signIn('Alice', old, migrationEmail: email),
        'Alice',
      );
      expect((await db.getUserByEmail('Alice'))!['email'], email);
    },
  );

  test(
    'unknown device creates a local Firebase cache without storing a password',
    () async {
      backend.seed(email, cloud);
      expect(await service.signIn(email, cloud), email);
      expect(
        (await db.getUserByEmail(email))!['password_hash'],
        'FIREBASE_AUTH_ONLY',
      );
      expect((await db.getAllSavedAccounts()).single.isGoogleAccount, false);
    },
  );

  test(
    'registration saves a pending Firebase identity and sends verification',
    () async {
      await expectLater(
        service.register('Alice', email, cloud),
        throwsA(isA<FirebaseEmailVerificationRequired>()),
      );
      expect((await db.firebaseIdentity('Alice'))!['email'], email);
      expect(
        (await db.getUserByEmail('Alice'))!['password_hash'],
        'FIREBASE_AUTH_ONLY',
      );
      expect(backend.verifications, 1);
      await expectLater(
        service.signIn('Alice', cloud),
        throwsA(isA<FirebaseEmailVerificationRequired>()),
      );
      backend.seed(email, cloud, uid: 'new-$email');
      expect(await service.signIn('Alice', cloud), 'Alice');
    },
  );

  test(
    'duplicate local registration never creates an orphan Firebase account',
    () async {
      await legacy();
      await expectLater(
        service.register('Alice', 'other@example.test', cloud),
        throwsStateError,
      );
      await expectLater(
        service.register('Other', email, cloud),
        throwsStateError,
      );
      expect(backend.creates, 0);
    },
  );

  test(
    'Firebase reset and server password change leave SQLite credentials unchanged',
    () async {
      await legacy();
      backend.seed(email, old);
      await service.signIn('Alice', old);
      final before = await db.getUserByEmail('Alice');
      await service.sendPasswordReset('Alice');
      expect(backend.resetEmail, email);
      await service.changePassword('Alice', old, cloud);
      expect(await db.getUserByEmail('Alice'), before);
      expect(await service.signIn('Alice', cloud), 'Alice');
      await expectLater(
        service.signIn('Alice', old),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(await db.changePassword('Alice', old, 'AnotherSecret!789'), false);
      expect(await db.updatePasswordByEmail(email, old), false);
      await expectLater(
        db.bindEmailToUser('Alice', 'other@example.test'),
        throwsStateError,
      );
    },
  );

  test(
    'unknown reset account receives the same result without local mutation',
    () async {
      await legacy();
      backend.resetError = 'user-not-found';
      await service.sendPasswordReset('unknown@example.test');
      expect(await db.authenticateUser('Alice', old), true);
      expect(await db.firebaseIdentity('Alice'), isNull);
    },
  );

  test(
    'offline recovery and failed reauthentication never change credentials',
    () async {
      await legacy();
      backend.seed(email, old);
      await service.signIn('Alice', old);
      await expectLater(
        service.changePassword('Alice', 'wrong', cloud),
        throwsA(isA<FirebaseAuthException>()),
      );
      backend.offline = true;
      await expectLater(
        service.sendPasswordReset(email),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(backend.passwords[email], old);
    },
  );

  test(
    'Google sign-in preserves canonical local username and requires local proof',
    () async {
      await legacy();
      backend.seed(email, cloud, providers: {'google.com'});
      backend.current = backend.accounts[email];
      await expectLater(
        service.acceptGoogle(backend.current!),
        throwsA(isA<LocalVaultProofRequired>()),
      );
      expect(
        await service.acceptGoogle(backend.current!, localPassword: old),
        'Alice',
      );
      expect((await db.loadTransactions('Alice')).single.id, 'kept-tx');
      expect(await service.acceptGoogle(backend.current!), 'Alice');
    },
  );

  test(
    'one UID cannot attach two local vaults and deletion removes only its mapping',
    () async {
      await legacy();
      backend.seed(email, old);
      await service.signIn('Alice', old);
      await expectLater(
        db.attachFirebaseIdentity(
          username: 'Other',
          uid: 'uid-alice',
          email: email,
          provider: 'password',
          checkSession: () {},
        ),
        throwsStateError,
      );
      await db.deleteSavedAccount('Alice');
      expect(await db.firebaseUsernameForUid('uid-alice'), isNull);
    },
  );

  test(
    'an already unlocked local vault can attach verified Google without changing its username',
    () async {
      await legacy();
      backend.seed(email, cloud, providers: {'google.com'});
      backend.current = backend.accounts[email];
      expect(
        await service.acceptGoogle(backend.current!, localUnlockProven: true),
        'Alice',
      );
      expect((await db.loadTransactions('Alice')).single.id, 'kept-tx');
    },
  );

  test(
    'app state loads the UID by canonical vault name and clears it on account change',
    () async {
      await legacy();
      backend.seed(email, old);
      await service.signIn('Alice', old);
      await AppState.loadAllUserData('Alice');
      expect(AppState.firebaseUid, 'uid-alice');
      AppState.currentUser = 'Other';
      expect(AppState.firebaseUid, isNull);
    },
  );

  testWidgets(
    'reset dialog uses hosted links and never collects a new password',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordRecoveryDialog(initialEmail: email, service: service),
          ),
        ),
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('recovery_submit')));
        for (var i = 0; i < 100 && backend.resetEmail == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(backend.resetEmail, email);
      expect(
        find.textContaining('If this email has a Firebase password account'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recovery_code')), findsNothing);
      expect(find.byKey(const Key('recovery_password')), findsNothing);
      expect(find.text('Return to sign in'), findsOneWidget);
    },
  );
}
