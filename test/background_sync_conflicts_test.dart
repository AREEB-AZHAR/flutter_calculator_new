import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/models/transaction.dart' as model;
import 'package:balance_tracker/models/user_profile.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/services/ledger_sync.dart';
import 'package:balance_tracker/services/sync_fingerprint.dart';
import 'package:balance_tracker/services/sync_metadata.dart';

class BatchRemote implements LedgerRemote {
  LedgerRecords records = {'transactions': {}, 'goals': {}};
  final batches = <int>[];
  bool failNext = false;
  Future<void> Function()? afterCommit;
  @override
  Future<LedgerRecords> read() async => {
    for (final c in records.entries)
      c.key: {
        for (final r in c.value.entries)
          r.key: Map<String, dynamic>.from(r.value),
      },
  };
  @override
  Future<void> commit(List<LedgerWrite> writes) async {
    if (failNext) {
      failNext = false;
      throw StateError('network unavailable');
    }
    batches.add(writes.length);
    for (final write in writes) {
      records[write.collection]![write.id] = {...write.data};
    }
    final callback = afterCommit;
    afterCommit = null;
    await callback?.call();
  }
}

model.Transaction tx(String id, {double amount = 1, String title = 'Sample'}) =>
    model.Transaction(
      id: id,
      title: title,
      amount: amount,
      date: DateTime(2026, 10, 25),
      isIncome: false,
      category: 'Food & Dining',
      account: 'Cash',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const user = 'background@example.test';
  final database = AppDatabase.instance;
  late SqliteLedgerStore local;
  late BatchRemote remote;
  late LedgerSyncEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'legacy_prefs_migrated': true});
    final db = await database.database;
    for (final table in [
      'transactions',
      'goals',
      'goal_entries',
      'accounts',
      'budgets',
      'profiles',
      'ledger_outbox',
      'ledger_sync_baselines',
      'ledger_import_guard',
    ]) {
      await db.delete(table);
    }
    local = SqliteLedgerStore(db);
    remote = BatchRemote();
    engine = LedgerSyncEngine(local, remote, checkSession: () {});
  });

  test('identical nonempty copies do not produce a login conflict', () async {
    await database.insertTransaction(user, tx('same'));
    remote.records['transactions']!['same'] = tx('same').toJson();
    expect(await engine.sync(user, detectConflicts: true), true);
    expect(await engine.sync(user, detectConflicts: true), true);
    expect((await local.snapshot(user)).pending, isEmpty);
  });

  test(
    'new offline records and cloud-only additions merge without prompting',
    () async {
      await database.insertTransaction(user, tx('device'));
      remote.records['transactions']!['cloud'] = tx('cloud').toJson();
      expect(await engine.sync(user, detectConflicts: true), true);
      expect((await database.loadTransactions(user)).map((t) => t.id).toSet(), {
        'device',
        'cloud',
      });
    },
  );

  test(
    'queued offline edit against acknowledged cloud version is ordinary sync',
    () async {
      await database.insertTransaction(user, tx('edit'));
      await engine.sync(user, detectConflicts: true);
      await database.insertTransaction(user, tx('edit', amount: 2));
      expect(await engine.sync(user, detectConflicts: true), true);
      expect(remote.records['transactions']!['edit']!['amount'], 2);
    },
  );

  test(
    'cloud-only edit is pulled without a false conflict or echo write',
    () async {
      await database.insertTransaction(user, tx('edit'));
      await engine.sync(user, detectConflicts: true);
      remote.records['transactions']!['edit'] = tx('edit', amount: 3).toJson();
      final commits = remote.batches.length;
      expect(await engine.sync(user, detectConflicts: true), true);
      expect((await database.loadTransactions(user)).single.amount, 3);
      expect(remote.batches.length, commits);
    },
  );

  test(
    'both sides edit the same record: retain both versions and queued edit',
    () async {
      await database.insertTransaction(user, tx('edit'));
      await engine.sync(user, detectConflicts: true);
      await database.insertTransaction(
        user,
        tx('edit', title: 'Device change'),
      );
      remote.records['transactions']!['edit'] = tx(
        'edit',
        title: 'Cloud change',
      ).toJson();
      await expectLater(
        engine.sync(user, detectConflicts: true),
        throwsA(isA<LedgerConflictException>()),
      );
      expect(
        (await database.loadTransactions(user)).single.title,
        'Device change',
      );
      expect(remote.records['transactions']!['edit']!['title'], 'Cloud change');
      expect((await local.snapshot(user)).pending, hasLength(1));
    },
  );

  test(
    'legacy same-ID mismatch without a common version needs review',
    () async {
      await database.insertTransaction(user, tx('legacy', title: 'Device'));
      remote.records['transactions']!['legacy'] = tx(
        'legacy',
        title: 'Cloud',
      ).toJson();
      await expectLater(
        engine.sync(user, detectConflicts: true),
        throwsA(isA<LedgerConflictException>()),
      );
      expect(remote.batches, isEmpty);
    },
  );

  test('no-op save cannot replace a newer remote edit', () async {
    await database.insertTransaction(user, tx('edit'));
    await engine.sync(user, detectConflicts: true);
    await database.insertTransaction(user, tx('edit'));
    remote.records['transactions']!['edit'] = tx(
      'edit',
      title: 'New cloud value',
    ).toJson();
    expect(await engine.sync(user, detectConflicts: true), true);
    expect(
      (await database.loadTransactions(user)).single.title,
      'New cloud value',
    );
    expect(
      remote.records['transactions']!['edit']!['title'],
      'New cloud value',
    );
  });

  test('failed network commit retains pending records for retry', () async {
    await database.insertTransaction(user, tx('offline'));
    remote.failNext = true;
    await expectLater(
      engine.sync(user, detectConflicts: true),
      throwsStateError,
    );
    expect((await local.snapshot(user)).pending, hasLength(1));
    expect(await engine.sync(user, detectConflicts: true), true);
  });

  test('remote deletion without a local edit is applied quietly', () async {
    await database.insertTransaction(user, tx('deleted'));
    await engine.sync(user, detectConflicts: true);
    remote.records['transactions']!['deleted'] = {
      'id': 'deleted',
      '_deleted': true,
    };
    expect(await engine.sync(user, detectConflicts: true), true);
    expect(await database.loadTransactions(user), isEmpty);
  });

  test('remote deletion conflicts with a queued local edit', () async {
    await database.insertTransaction(user, tx('deleted'));
    await engine.sync(user, detectConflicts: true);
    await database.insertTransaction(user, tx('deleted', amount: 2));
    remote.records['transactions']!['deleted'] = {
      'id': 'deleted',
      '_deleted': true,
    };
    await expectLater(
      engine.sync(user, detectConflicts: true),
      throwsA(isA<LedgerConflictException>()),
    );
    expect((await database.loadTransactions(user)).single.amount, 2);
    expect((await local.snapshot(user)).pending, hasLength(1));
  });

  test('local deletion conflicts with a newer cloud edit', () async {
    await database.insertTransaction(user, tx('deleted'));
    await engine.sync(user, detectConflicts: true);
    await database.deleteSingleTransaction('deleted', username: user);
    remote.records['transactions']!['deleted'] = tx(
      'deleted',
      amount: 3,
    ).toJson();
    await expectLater(
      engine.sync(user, detectConflicts: true),
      throwsA(isA<LedgerConflictException>()),
    );
    expect((await local.snapshot(user)).pending.single.data['_deleted'], true);
    expect(remote.records['transactions']!['deleted']!['amount'], 3);
  });

  test('edit made during upload remains queued for the next batch', () async {
    await database.insertTransaction(user, tx('during'));
    remote.afterCommit = () =>
        database.insertTransaction(user, tx('during', amount: 9));
    expect(await engine.sync(user, detectConflicts: true), false);
    expect((await local.snapshot(user)).pending, hasLength(1));
    expect((await database.loadTransactions(user)).single.amount, 9);
    expect(await engine.sync(user, detectConflicts: true), true);
    expect(remote.records['transactions']!['during']!['amount'], 9);
  });

  test('explicit cloud resolution checkpoints the next quiet login', () async {
    await database.insertTransaction(user, tx('conflict'));
    await engine.sync(user, detectConflicts: true);
    await database.insertTransaction(user, tx('conflict', amount: 2));
    remote.records['transactions']!['conflict'] = tx(
      'conflict',
      amount: 3,
    ).toJson();
    await expectLater(
      engine.sync(user, detectConflicts: true),
      throwsA(isA<LedgerConflictException>()),
    );
    expect(await engine.restore(user), true);
    expect(await engine.sync(user, detectConflicts: true), true);
    expect((await database.loadTransactions(user)).single.amount, 3);
  });

  test('metadata bursts coalesce and remain isolated by account', () async {
    for (var i = 0; i < 100; i++) {
      await database.saveAccounts(user, ['Wallet $i']);
    }
    await database.saveAccounts('other@example.test', ['Other wallet']);
    final store = MetadataSyncStore(await database.database);
    expect((await store.snapshot(user)).revisions, hasLength(1));
    expect((await store.snapshot(user)).accounts, ['Wallet 99']);
    expect((await store.snapshot('other@example.test')).accounts, [
      'Other wallet',
    ]);
  });

  test(
    'additive checkpoint installation is idempotent and preserves data',
    () async {
      await database.insertTransaction(user, tx('preserved'));
      final db = await database.database;
      await SqliteLedgerStore.install(db);
      await SqliteLedgerStore.install(db);
      expect((await database.loadTransactions(user)).single.id, 'preserved');
      expect((await local.snapshot(user)).pending, hasLength(1));
    },
  );

  test('more than 400 changes use bounded atomic chunks', () async {
    final db = await database.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < 1001; i++) {
        batch.insert(
          'transactions',
          SqliteLedgerStore.transactionRow(user, tx('batch_$i')),
        );
      }
      await batch.commit(noResult: true);
    });
    expect(await engine.sync(user, detectConflicts: true), true);
    expect(remote.batches, [400, 400, 201]);
  });

  test(
    'checkpoint survives store recreation and detects later concurrent edits',
    () async {
      await database.insertTransaction(user, tx('edit'));
      await engine.sync(user, detectConflicts: true);
      final restarted = LedgerSyncEngine(
        SqliteLedgerStore(await database.database),
        remote,
        checkSession: () {},
      );
      await database.insertTransaction(user, tx('edit', amount: 2));
      remote.records['transactions']!['edit'] = tx('edit', amount: 3).toJson();
      await expectLater(
        restarted.sync(user, detectConflicts: true),
        throwsA(isA<LedgerConflictException>()),
      );
    },
  );

  test('fingerprints ignore server timestamps and numeric representation', () {
    final a = tx('same').toJson();
    final b = {
      ...a,
      'amount': 1,
      '_updatedAt': 'server-only',
      '_deleted': false,
    };
    expect(
      syncFingerprint('transactions', 'same', a),
      syncFingerprint('transactions', 'same', b),
    );
    expect(
      syncFingerprint('transactions', 'same', a),
      isNot(
        syncFingerprint('transactions', 'same', {...b, 'title': 'Changed'}),
      ),
    );
  });

  test(
    'profile, accounts and budgets enqueue durably without entering ledger batches',
    () async {
      await database.saveProfile(
        UserProfile(username: user, displayName: 'Sample'),
      );
      await database.saveAccounts(user, ['Cash', 'Bank']);
      await database.saveBudgets(user, {'Food': 10});
      expect((await local.snapshot(user)).pending, isEmpty);
      final captured = await MetadataSyncStore(
        await database.database,
      ).snapshot(user);
      expect(captured.revisions.keys.toSet(), {
        'accounts',
        'budgets',
        'profile',
      });
      expect(captured.accounts, unorderedEquals(['Cash', 'Bank']));
    },
  );

  test(
    'metadata changed during upload is not overwritten or acknowledged',
    () async {
      final store = MetadataSyncStore(await database.database);
      await database.saveAccounts(user, ['Cash', 'Bank']);
      final before = await store.snapshot(user);
      await database.saveAccounts(user, ['Cash', 'New wallet']);
      await store.complete(
        user,
        before,
        before.accounts,
        before.budgets,
        () {},
        profileUploaded: true,
      );
      final after = await store.snapshot(user);
      expect(after.accounts, ['Cash', 'New wallet']);
      expect(after.revisions['accounts'], isNot(before.revisions['accounts']));
    },
  );

  test(
    'failed local metadata transaction does not queue a partial account list',
    () async {
      final store = MetadataSyncStore(await database.database);
      await database.saveAccounts(user, ['Cash']);
      final before = await store.snapshot(user);
      await expectLater(
        database.saveAccounts(user, ['Duplicate', 'Duplicate']),
        throwsA(anything),
      );
      final after = await store.snapshot(user);
      expect(after.accounts, ['Cash']);
      expect(after.revisions['accounts'], before.revisions['accounts']);
    },
  );

  test(
    'deletion markers for metadata persist an intentionally empty map',
    () async {
      final store = MetadataSyncStore(await database.database);
      await database.saveBudgets(user, {});
      final before = await store.snapshot(user);
      expect(before.budgets, isEmpty);
      await store.complete(
        user,
        before,
        before.accounts,
        {},
        () {},
        profileUploaded: true,
      );
      expect((await store.snapshot(user)).budgets, isEmpty);
      expect(await store.hasPending(user), false);
    },
  );

  test(
    'removing a local account also clears its checkpoints and queued work',
    () async {
      await database.insertTransaction(user, tx('owned'));
      await engine.sync(user, detectConflicts: true);
      await database.saveAccounts(user, ['Cash']);
      await database.deleteLocalUser(user);
      final db = await database.database;
      expect(
        await db.query(
          'ledger_sync_baselines',
          where: 'username = ?',
          whereArgs: [user],
        ),
        isEmpty,
      );
      expect(
        await db.query(
          'ledger_outbox',
          where: 'username = ?',
          whereArgs: [user],
        ),
        isEmpty,
      );
    },
  );
}
