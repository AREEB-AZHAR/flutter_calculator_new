import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_tracker/models/transaction.dart' as model;
import 'package:balance_tracker/models/planned_transaction.dart';
import 'package:balance_tracker/models/savings_goal.dart';
import 'package:balance_tracker/models/goal_entry.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/services/ledger_sync.dart';
import 'package:balance_tracker/services/atomic_plans.dart';

class MemoryRemote implements LedgerRemote {
  LedgerRecords records = {'transactions': {}, 'goals': {}};
  final List<int> batches = [];
  int? failCommit;
  Future<void> Function()? afterCommit;
  Future<void> Function()? afterRead;
  int reads = 0;

  @override
  Future<LedgerRecords> read() async {
    reads++;
    final result = <String, Map<String, Map<String, dynamic>>>{
      for (final c in records.entries)
        c.key: {
          for (final e in c.value.entries)
            e.key: Map<String, dynamic>.from(
              jsonDecode(jsonEncode(e.value)) as Map,
            ),
        },
    };
    await afterRead?.call();
    return result;
  }

  @override
  Future<void> commit(List<LedgerWrite> writes) async {
    if (failCommit == batches.length + 1) {
      throw StateError('Injected offline failure');
    }
    expect(writes.length, lessThanOrEqualTo(400));
    batches.add(writes.length);
    for (final w in writes) {
      records[w.collection]![w.id] = Map.of(w.data);
    }
    await afterCommit?.call();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Database db;
  late SqliteLedgerStore local;
  late MemoryRemote remote;
  const user = 'alice@example.test';
  const other = 'bob@example.test';
  final now = DateTime(2026, 10, 23, 12);
  model.Transaction tx(String id, {double amount = 10}) => model.Transaction(
    id: id,
    title: 'Transaction $id',
    amount: amount,
    date: now,
    isIncome: false,
  );
  LedgerSyncEngine engine({void Function()? guard}) =>
      LedgerSyncEngine(local, remote, checkSession: guard ?? () {});

  Future<void> seed(int count) async {
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < count; i++) {
        batch.insert(
          'transactions',
          SqliteLedgerStore.transactionRow(user, tx('tx_$i')),
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> reopen() async {
    await AppDatabase.instance.close();
    db = await AppDatabase.instance.database;
    local = SqliteLedgerStore(db);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'legacy_prefs_migrated': true});
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp(
      'tally-ledger-regression-',
    );
    await databaseFactoryFfi.setDatabasesPath(directory.path);
    databaseFactory = databaseFactoryFfi;
    db = await AppDatabase.instance.database;
  });
  setUp(() async {
    for (final table in [
      'transactions',
      'goals',
      'goal_entries',
      'planned_transactions',
      'ledger_outbox',
      'ledger_import_guard',
    ]) {
      await db.delete(table);
    }
    local = SqliteLedgerStore(db);
    remote = MemoryRemote();
  });
  tearDownAll(() async {
    await AppDatabase.instance.close();
    await directory.delete(recursive: true);
  });

  group('Durable ledger synchronization', () {
    test(
      'two persisted devices preserve independent additions and propagate explicit deletion',
      () async {
        await seed(1);
        await engine().sync(user);
        final devicePath = '${directory.path}/device-b.db';
        await db.execute('VACUUM INTO ?', [devicePath]);
        final deviceB = await databaseFactoryFfi.openDatabase(devicePath);
        try {
          final storeB = SqliteLedgerStore(deviceB);
          final syncB = LedgerSyncEngine(storeB, remote, checkSession: () {});
          await deviceB.insert(
            'transactions',
            SqliteLedgerStore.transactionRow(user, tx('device-b-only')),
          );
          await syncB.sync(user);
          await engine().sync(user);
          expect(
            (await AppDatabase.instance.loadTransactions(
              user,
            )).map((t) => t.id),
            containsAll(['tx_0', 'device-b-only']),
          );
          await AppDatabase.instance.deleteSingleTransaction(
            'tx_0',
            username: user,
          );
          await engine().sync(user);
          await syncB.sync(user);
          expect((await storeB.snapshot(user)).records['transactions']!.keys, [
            'device-b-only',
          ]);
          expect(remote.records['transactions']!['tx_0']!['_deleted'], true);
        } finally {
          await deviceB.close();
        }
      },
    );

    test(
      'version 1 ledger migrates without dropping records and bootstraps safely',
      () async {
        await seed(1);
        for (final table in SqliteLedgerStore.collections) {
          for (final event in ['INSERT', 'UPDATE', 'DELETE']) {
            await db.execute('DROP TRIGGER ledger_${table}_$event');
          }
        }
        await db.execute('DROP TABLE ledger_outbox');
        await db.execute('DROP TABLE ledger_import_guard');
        await db.execute(
          'ALTER TABLE planned_transactions DROP COLUMN anchor_day',
        );
        await db.execute(
          'ALTER TABLE planned_transactions DROP COLUMN anchor_month',
        );
        await db.setVersion(1);
        await reopen();
        expect(await db.getVersion(), 2);
        expect(
          (await AppDatabase.instance.loadTransactions(user)).single.id,
          'tx_0',
        );
        expect(await engine().sync(user), isTrue);
        expect(remote.records['transactions']!.keys, ['tx_0']);
        await AppDatabase.instance.insertTransaction(
          user,
          tx('post-migration'),
        );
        expect(
          (await local.snapshot(user)).pending.single.id,
          'post-migration',
        );
      },
    );

    test(
      'uncertain remote commit is retried idempotently after restart',
      () async {
        await seed(1);
        remote.afterCommit = () async {
          remote.afterCommit = null;
          throw StateError('Connection lost after server committed');
        };
        await expectLater(engine().sync(user), throwsStateError);
        await reopen();
        expect((await local.snapshot(user)).pending.length, 1);
        expect(await engine().sync(user), isTrue);
        expect(remote.records['transactions']!.keys, ['tx_0']);
      },
    );

    for (final count in [0, 1, 400, 401, 1000, 100000]) {
      test(
        'uploads every one of $count records and checkpoints all chunks',
        () async {
          await seed(count);
          expect(await engine().sync(user), isTrue);
          expect(remote.records['transactions']!.length, count);
          for (var i = 0; i < count; i++) {
            expect(remote.records['transactions']!['tx_$i']!['amount'], 10);
          }
          expect((await local.snapshot(user)).pending, isEmpty);
          final commits = remote.batches.length;
          expect(await engine().sync(user), isTrue);
          expect(
            remote.batches.length,
            commits,
            reason: 'Unchanged records must not be uploaded again',
          );
        },
        timeout: const Timeout(Duration(minutes: 4)),
      );
    }

    test(
      'stale nonempty device preserves cloud-only transactions/goals and entries',
      () async {
        await seed(1);
        remote.records['transactions']!['cloud-only'] = tx(
          'cloud-only',
          amount: 42,
        ).toJson();
        final goal = SavingsGoal(
          id: 'cloud-goal',
          title: 'Vacation',
          target: 500,
          saved: 25,
          entries: [
            GoalEntry(id: 'entry', goalId: 'cloud-goal', amount: 25, date: now),
          ],
        );
        remote.records['goals']![goal.id] = goal.toJson();
        expect(await engine().sync(user), isTrue);
        expect(
          remote.records['transactions']!.keys,
          containsAll(['tx_0', 'cloud-only']),
        );
        final goals = await AppDatabase.instance.loadGoals(user);
        expect(goals.single.entries.single.amount, 25);
        expect((await AppDatabase.instance.loadTransactions(user)).length, 2);
      },
    );

    test(
      'interrupted second chunk survives reopen and retries only unacknowledged changes',
      () async {
        await seed(801);
        remote.failCommit = 2;
        await expectLater(engine().sync(user), throwsStateError);
        expect(remote.records['transactions']!.length, 400);
        await reopen();
        expect((await local.snapshot(user)).pending.length, 401);
        remote.failCommit = null;
        expect(await engine().sync(user), isTrue);
        expect(remote.records['transactions']!.length, 801);
        expect(remote.batches, [400, 400, 1]);
      },
    );

    test(
      'offline transaction/goal deletion and undo survive restart without resurrection',
      () async {
        await AppDatabase.instance.insertTransaction(user, tx('delete-me'));
        await AppDatabase.instance.upsertGoal(
          user,
          SavingsGoal(id: 'delete-goal', title: 'Goal', target: 100),
        );
        await engine().sync(user);
        await AppDatabase.instance.deleteSingleTransaction(
          'delete-me',
          username: user,
        );
        await AppDatabase.instance.softDeleteGoal(user, 'delete-goal');
        await reopen();
        remote.failCommit = remote.batches.length + 1;
        await expectLater(engine().sync(user), throwsStateError);
        expect((await local.snapshot(user)).pending.length, 2);
        remote.failCommit = null;
        await engine().sync(user);
        expect(remote.records['transactions']!['delete-me']!['_deleted'], true);
        expect(remote.records['goals']!['delete-goal']!['_deleted'], true);
        // A stale downloaded copy is unedited: it must honor the remote tombstone.
        await local.applyRemote(user, {
          'transactions': {'delete-me': tx('delete-me').toJson()},
          'goals': {},
        }, () {});
        await engine().sync(user);
        expect(await AppDatabase.instance.loadTransactions(user), isEmpty);
        // An explicit undo is a new mutation and can restore the record.
        await AppDatabase.instance.insertTransaction(user, tx('delete-me'));
        await engine().sync(user);
        expect(
          remote.records['transactions']!['delete-me']!['_deleted'],
          false,
        );
      },
    );

    test(
      'edit during acknowledgment retains its newer revision and survives import',
      () async {
        await seed(1);
        remote.afterCommit = () async {
          remote.afterCommit = null;
          await AppDatabase.instance.insertTransaction(
            user,
            tx('tx_0', amount: 99),
          );
        };
        expect(await engine().sync(user), isFalse);
        expect((await local.snapshot(user)).pending.single.data['amount'], 99);
        expect(
          (await AppDatabase.instance.loadTransactions(user)).single.amount,
          99,
        );
        expect(await engine().sync(user), isTrue);
        expect(remote.records['transactions']!['tx_0']!['amount'], 99);
      },
    );

    test('session switch aborts before upload and preserves outbox', () async {
      await seed(1);
      var active = true;
      remote.afterRead = () async {
        active = false;
      };
      await expectLater(
        engine(
          guard: () {
            if (!active) throw StateError('Account changed');
          },
        ).sync(user),
        throwsStateError,
      );
      expect(remote.batches, isEmpty);
      expect((await local.snapshot(user)).pending.length, 1);
    });

    test('session switch during import rolls back all local changes', () async {
      remote.records['transactions']!['remote'] = tx('remote').toJson();
      var checks = 0;
      await expectLater(
        local.applyRemote(user, remote.records, () {
          if (++checks == 3) throw StateError('Account changed');
        }),
        throwsStateError,
      );
      expect(await AppDatabase.instance.loadTransactions(user), isEmpty);
      expect(await db.query('ledger_import_guard'), isEmpty);
    });

    test('outbox and imported data stay scoped to the account', () async {
      await AppDatabase.instance.insertTransaction(other, tx('bob-only'));
      await seed(1);
      await engine().sync(user);
      expect(remote.records['transactions']!.containsKey('bob-only'), isFalse);
      expect((await local.snapshot(other)).pending.length, 1);
      remote.records['transactions']!['bob-only'] = tx('bob-only').toJson();
      await expectLater(engine().sync(user), throwsStateError);
      expect(
        (await AppDatabase.instance.loadTransactions(other)).single.id,
        'bob-only',
      );
    });

    test(
      'ordinary sync prefers remote over an unedited legacy conflict',
      () async {
        await db.insert('ledger_import_guard', {'id': 1});
        await AppDatabase.instance.insertTransaction(
          user,
          tx('shared', amount: 10),
        );
        await db.delete('ledger_import_guard');
        remote.records['transactions']!['shared'] = tx(
          'shared',
          amount: 50,
        ).toJson();
        await engine().sync(user);
        expect(remote.batches, isEmpty);
        expect(
          (await AppDatabase.instance.loadTransactions(user)).single.amount,
          50,
        );
      },
    );

    test(
      'explicit replacement handles more than 400 writes, including deletions',
      () async {
        await seed(401);
        for (var i = 0; i < 450; i++) {
          remote.records['transactions']!['old_$i'] = tx('old_$i').toJson();
        }
        expect(await engine().overwrite(user), isTrue);
        expect(
          remote.records['transactions']!.values
              .where((r) => r['_deleted'] != true)
              .length,
          401,
        );
        expect(remote.batches.fold<int>(0, (n, size) => n + size), 851);
      },
    );

    test(
      'explicit restore replaces local ledger/goal entries without echo uploads',
      () async {
        await seed(1);
        remote.records['transactions']!['remote'] = tx('remote').toJson();
        expect(await engine().restore(user), isTrue);
        expect(
          (await AppDatabase.instance.loadTransactions(user)).single.id,
          'remote',
        );
        expect((await local.snapshot(user)).pending, isEmpty);
        expect(remote.batches, isEmpty);
      },
    );

    test(
      'payload size also bounds chunks; oversized documents remain pending',
      () async {
        final writes = List.generate(
          20,
          (i) => LedgerWrite('transactions', '$i', {'value': 'x' * 500000}),
        );
        await LedgerSyncEngine.commitBounded(remote, writes, () {});
        expect(remote.batches.length, greaterThan(1));
        await expectLater(
          LedgerSyncEngine.commitBounded(remote, [
            LedgerWrite('transactions', 'too-big', {'value': 'x' * 1000000}),
          ], () {}),
          throwsStateError,
        );
      },
    );
  });

  group('Atomic planned and recurring transactions', () {
    PlannedTransaction plan({
      String id = 'plan',
      String recurrence = 'Monthly',
      DateTime? date,
    }) => PlannedTransaction(
      id: id,
      title: 'Rent',
      amount: 100,
      date: date ?? DateTime(2026, 10, 1),
      isIncome: false,
      recurrence: recurrence,
    );

    test(
      'automatic/manual concurrent retries create one occurrence, outbox entry and successor',
      () async {
        final p = plan();
        await AppDatabase.instance.savePlannedTransaction(user, p);
        final processor = AtomicPlans(db);
        final results = await Future.wait([
          processor.process(user, p.id, now: now),
          processor.process(user, p.id, now: now, force: true),
        ]);
        expect(results.whereType<ProcessedPlan>().length, 1);
        expect(
          (await AppDatabase.instance.loadTransactions(user)).single.id,
          p.id,
        );
        expect((await local.snapshot(user)).pending.single.id, p.id);
        expect(
          (await AppDatabase.instance.loadPlannedTransactions(user)).single.id,
          AtomicPlans.successor(p)!.id,
        );
        await reopen();
        expect(await AtomicPlans(db).process(user, p.id, now: now), isNull);
        expect((await AppDatabase.instance.loadTransactions(user)).length, 1);
      },
    );

    for (final failure in ['occurrence', 'processed', 'successor']) {
      test(
        'failure at $failure rolls back ledger, flag, successor and outbox; restart retries safely',
        () async {
          final p = plan();
          await AppDatabase.instance.savePlannedTransaction(user, p);
          final clause = switch (failure) {
            'occurrence' => "BEFORE INSERT ON transactions",
            'processed' =>
              "BEFORE UPDATE OF is_processed ON planned_transactions",
            _ => "BEFORE INSERT ON planned_transactions WHEN NEW.id != 'plan'",
          };
          await db.execute(
            "CREATE TRIGGER fail_plan $clause BEGIN SELECT RAISE(ABORT, 'injected write failure'); END",
          );
          await expectLater(
            AtomicPlans(db).process(user, p.id, now: now),
            throwsA(isA<DatabaseException>()),
          );
          expect(await AppDatabase.instance.loadTransactions(user), isEmpty);
          expect(
            (await AppDatabase.instance.loadPlannedTransactions(
              user,
            )).single.id,
            p.id,
          );
          expect((await local.snapshot(user)).pending, isEmpty);
          await db.execute('DROP TRIGGER fail_plan');
          await reopen();
          expect(
            await AtomicPlans(db).process(user, p.id, now: now),
            isNotNull,
          );
          await engine().sync(user);
          expect(remote.records['transactions']!.keys, [p.id]);
        },
      );
    }

    test(
      'catch-up records every missed day and leaves future plans untouched',
      () async {
        await AppDatabase.instance.savePlannedTransaction(
          user,
          plan(recurrence: 'Daily', date: DateTime(2026, 10, 20)),
        );
        final results = await AtomicPlans(db).processDue(user, now: now);
        expect(results.length, 4);
        expect((await AppDatabase.instance.loadTransactions(user)).length, 4);
        expect(
          (await AppDatabase.instance.loadPlannedTransactions(
            user,
          )).single.date,
          DateTime(2026, 10, 24),
        );
        expect(await AtomicPlans(db).processDue(user, now: now), isEmpty);
      },
    );

    test('month end and leap year clamping preserve original anchors', () {
      final january = plan(date: DateTime(2028, 1, 31, 15, 30));
      final february = AtomicPlans.successor(january)!;
      expect(february.date, DateTime(2028, 2, 29, 15, 30));
      expect(
        AtomicPlans.successor(february)!.date,
        DateTime(2028, 3, 31, 15, 30),
      );
      var yearly = plan(date: DateTime(2028, 2, 29), recurrence: 'Yearly');
      for (var i = 0; i < 4; i++) {
        yearly = AtomicPlans.successor(yearly)!;
      }
      expect(yearly.date, DateTime(2032, 2, 29));
    });

    test('manual future execution is atomic and account-scoped', () async {
      final p = plan(date: DateTime(2027));
      await AppDatabase.instance.savePlannedTransaction(user, p);
      expect(
        await AtomicPlans(db).process(other, p.id, now: now, force: true),
        isNull,
      );
      expect(await AtomicPlans(db).process(user, p.id, now: now), isNull);
      expect(
        await AtomicPlans(db).process(user, p.id, now: now, force: true),
        isNotNull,
      );
    });
  });
}
