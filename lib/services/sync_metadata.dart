import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';
import 'sync_fingerprint.dart';

class MetadataSnapshot {
  final Map<String, int> revisions;
  final Map<String, String> baselines;
  final List<String> accounts;
  final Map<String, double> budgets;
  final UserProfile? profile;
  const MetadataSnapshot(
    this.revisions,
    this.baselines,
    this.accounts,
    this.budgets,
    this.profile,
  );
}

/// Metadata shares the durable outbox; existing cloud paths stay unchanged.
class MetadataSyncStore {
  final Database db;
  const MetadataSyncStore(this.db);
  static const collection = '_metadata';

  static Future<void> enqueue(
    DatabaseExecutor txn,
    String username,
    String kind,
  ) async {
    await txn.insert('ledger_outbox', {
      'username': username,
      'collection': collection,
      'entity_id': kind,
      'deleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MetadataSnapshot> snapshot(String username) => db.transaction((
    txn,
  ) async {
    final changes = await txn.query(
      'ledger_outbox',
      where: 'username = ? AND collection = ?',
      whereArgs: [username, collection],
    );
    final bases = await txn.query(
      'ledger_sync_baselines',
      where: 'username = ? AND collection = ?',
      whereArgs: [username, collection],
    );
    final revisions = {
      for (final r in changes) r['entity_id'] as String: r['revision'] as int,
    };
    final baselines = {
      for (final r in bases)
        r['entity_id'] as String: r['fingerprint'] as String,
    };
    final accounts = (await txn.query(
      'accounts',
      where: 'username = ?',
      whereArgs: [username],
    )).map((r) => r['name'] as String).toList();
    final budgets = {
      for (final r in await txn.query(
        'budgets',
        where: 'username = ?',
        whereArgs: [username],
      ))
        r['category'] as String: (r['amount_limit'] as num).toDouble(),
    };
    final profiles = await txn.query(
      'profiles',
      where: 'username = ?',
      whereArgs: [username],
    );
    return MetadataSnapshot(
      revisions,
      baselines,
      accounts.isEmpty &&
              !revisions.containsKey('accounts') &&
              !baselines.containsKey('accounts')
          ? ['Main', 'Cash', 'Credit Card', 'Digital Wallet']
          : accounts,
      budgets.isEmpty &&
              !revisions.containsKey('budgets') &&
              !baselines.containsKey('budgets')
          ? {
              'Food & Dining': 500,
              'Housing & Rent': 1500,
              'Transportation': 300,
              'Entertainment': 200,
            }
          : budgets,
      profiles.isEmpty ? null : UserProfile.fromMap(profiles.first),
    );
  });

  /// Never acknowledge or replace a newer local revision.
  Future<void> complete(
    String username,
    MetadataSnapshot captured,
    List<String> accounts,
    Map<String, double> budgets,
    void Function() checkSession, {
    required bool profileUploaded,
  }) => db.transaction((txn) async {
    checkSession();
    final current = {
      for (final r in await txn.query(
        'ledger_outbox',
        where: 'username = ? AND collection = ?',
        whereArgs: [username, collection],
      ))
        r['entity_id'] as String: r['revision'] as int,
    };
    for (final kind in [
      'accounts',
      'budgets',
      if (profileUploaded) 'profile',
    ]) {
      if (current[kind] != captured.revisions[kind]) continue;
      if (kind == 'accounts') {
        await txn.delete(
          'accounts',
          where: 'username = ?',
          whereArgs: [username],
        );
        for (final name in accounts) {
          await txn.insert('accounts', {'username': username, 'name': name});
        }
      } else if (kind == 'budgets') {
        await txn.delete(
          'budgets',
          where: 'username = ?',
          whereArgs: [username],
        );
        for (final e in budgets.entries) {
          await txn.insert('budgets', {
            'username': username,
            'category': e.key,
            'amount_limit': e.value,
          });
        }
      }
      if (captured.revisions[kind] != null) {
        await txn.delete(
          'ledger_outbox',
          where: 'username = ? AND collection = ? AND revision = ?',
          whereArgs: [username, collection, captured.revisions[kind]],
        );
      }
      if (kind != 'profile') {
        await txn.insert('ledger_sync_baselines', {
          'username': username,
          'collection': collection,
          'entity_id': kind,
          'fingerprint': syncFingerprint(
            collection,
            kind,
            kind == 'accounts' ? {'list': accounts} : {'categories': budgets},
          ),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    checkSession();
  });

  Future<bool> hasPending(
    String username, {
    bool includeProfile = true,
  }) async => (await db.query(
    'ledger_outbox',
    columns: ['revision'],
    where:
        'username = ? AND collection = ?${includeProfile ? '' : " AND entity_id != 'profile'"}',
    whereArgs: [username, collection],
    limit: 1,
  )).isNotEmpty;
}
