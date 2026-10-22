import 'dart:convert';
import 'package:flutter/material.dart' show Color;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/savings_goal.dart';
import '../models/goal_entry.dart';
import '../models/transaction.dart' as model;

typedef LedgerRecords = Map<String, Map<String, Map<String, dynamic>>>;

class LedgerWrite {
  final String collection;
  final String id;
  final Map<String, dynamic> data;
  final int? revision;
  const LedgerWrite(this.collection, this.id, this.data, {this.revision});
}

abstract interface class LedgerRemote {
  Future<LedgerRecords> read();
  Future<void> commit(List<LedgerWrite> writes);
}

class LedgerSnapshot {
  final LedgerRecords records;
  final List<LedgerWrite> pending;
  const LedgerSnapshot(this.records, this.pending);
}

/// A durable, coalescing outbox. Triggers enlist mutations in the SAME SQLite
/// transaction as the ledger write, including writes from recurring processing.
class SqliteLedgerStore {
  final Database db;
  const SqliteLedgerStore(this.db);
  static const collections = ['transactions', 'goals'];

  static Future<void> install(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS ledger_outbox (
      revision INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL, collection TEXT NOT NULL, entity_id TEXT NOT NULL,
      deleted INTEGER NOT NULL,
      UNIQUE(username, collection, entity_id))''');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS ledger_import_guard (id INTEGER PRIMARY KEY)',
    );
    for (final table in collections) {
      for (final event in ['INSERT', 'UPDATE', 'DELETE']) {
        final ref = event == 'DELETE' ? 'OLD' : 'NEW';
        await db.execute('''CREATE TRIGGER IF NOT EXISTS ledger_${table}_$event
          AFTER $event ON $table
          WHEN NOT EXISTS (SELECT 1 FROM ledger_import_guard)
          BEGIN
            INSERT OR REPLACE INTO ledger_outbox(username, collection, entity_id, deleted)
            VALUES ($ref.username, '$table', $ref.id, ${event == 'DELETE' ? 1 : 0});
          END''');
      }
    }
  }

  Future<LedgerSnapshot> snapshot(String username) => db.transaction((
    txn,
  ) async {
    final records = <String, Map<String, Map<String, dynamic>>>{};
    final txs = await txn.query(
      'transactions',
      where: 'username = ?',
      whereArgs: [username],
    );
    records['transactions'] = {
      for (final r in txs) r['id'] as String: transactionFromRow(r).toJson(),
    };
    final goals = await txn.query(
      'goals',
      where: 'username = ?',
      whereArgs: [username],
    );
    final entries = await txn.query(
      'goal_entries',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'date DESC',
    );
    final grouped = <String, List<GoalEntry>>{};
    for (final r in entries) {
      grouped
          .putIfAbsent(r['goal_id'] as String, () => [])
          .add(
            GoalEntry(
              id: r['id'] as String,
              goalId: r['goal_id'] as String,
              amount: (r['amount'] as num).toDouble(),
              date: DateTime.parse(r['date'] as String),
              note: r['note'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
            ),
          );
    }
    records['goals'] = {
      for (final r in goals)
        r['id'] as String: goalFromRow(r, grouped[r['id']] ?? []).toJson(),
    };
    final changes = await txn.query(
      'ledger_outbox',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'revision',
    );
    return LedgerSnapshot(records, [
      for (final r in changes)
        LedgerWrite(
          r['collection'] as String,
          r['entity_id'] as String,
          r['deleted'] == 1
              ? {'id': r['entity_id'], '_deleted': true}
              : {
                  ...records[r['collection']]![r['entity_id']]!,
                  '_deleted': false,
                },
          revision: r['revision'] as int,
        ),
    ]);
  });

  Future<void> acknowledge(
    String username,
    List<LedgerWrite> writes,
  ) => db.transaction((txn) async {
    final batch = txn.batch();
    for (final write in writes) {
      if (write.revision == null) continue;
      // A concurrent edit replaces the revision. Never acknowledge that newer edit.
      batch.delete(
        'ledger_outbox',
        where: 'username = ? AND revision = ?',
        whereArgs: [username, write.revision],
      );
    }
    await batch.commit(noResult: true);
  });

  /// Import remote records without generating echo writes. Pending local changes
  /// win until acknowledged; absence in a snapshot NEVER means deletion.
  Future<void> applyRemote(
    String username,
    LedgerRecords remote,
    void Function() checkSession, {
    int? discardPendingThrough,
  }) => db.transaction((txn) async {
    checkSession();
    await txn.insert('ledger_import_guard', {'id': 1});
    if (discardPendingThrough != null) {
      await txn.delete(
        'ledger_outbox',
        where: 'username = ? AND revision <= ?',
        whereArgs: [username, discardPendingThrough],
      );
    }
    final pending = await txn.query(
      'ledger_outbox',
      where: 'username = ?',
      whereArgs: [username],
    );
    final dirty = {
      for (final r in pending) '${r['collection']}/${r['entity_id']}',
    };
    final entryOwners = {
      for (final r in await txn.query(
        'goal_entries',
        columns: ['id', 'username'],
      ))
        r['id']: r['username'],
    };
    final batch = txn.batch();
    for (final collection in collections) {
      final existing = {
        for (final r in await txn.query(collection)) r['id']: r,
      };
      for (final entry in remote[collection]!.entries) {
        if (dirty.contains('$collection/${entry.key}')) continue;
        checkSession();
        final old = existing[entry.key];
        if (old != null && old['username'] != username) {
          throw StateError('Ledger ID belongs to another local account');
        }
        if (entry.value['_deleted'] == true) {
          batch.delete(
            collection,
            where: 'username = ? AND id = ?',
            whereArgs: [username, entry.key],
          );
          if (collection == 'goals') {
            batch.delete(
              'goal_entries',
              where: 'username = ? AND goal_id = ?',
              whereArgs: [username, entry.key],
            );
          }
        } else if (collection == 'transactions') {
          final row = transactionRow(
            username,
            model.Transaction.fromJson({...entry.value, 'id': entry.key}),
          );
          if (old == null || !row.entries.every((e) => old[e.key] == e.value)) {
            batch.insert(
              collection,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } else {
          final goal = SavingsGoal.fromJson({...entry.value, 'id': entry.key});
          batch.insert(
            collection,
            goalRow(username, goal),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          batch.delete(
            'goal_entries',
            where: 'username = ? AND goal_id = ?',
            whereArgs: [username, goal.id],
          );
          for (final e in goal.entries) {
            if (entryOwners[e.id] != null && entryOwners[e.id] != username) {
              throw StateError('Goal entry belongs to another account');
            }
            batch.insert('goal_entries', {
              'id': e.id,
              'goal_id': goal.id,
              'username': username,
              'amount': e.amount,
              'date': e.date.toIso8601String(),
              'note': e.note,
              'created_at': e.createdAt.toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    }
    checkSession();
    await batch.commit(noResult: true);
    checkSession();
    await txn.delete('ledger_import_guard');
  });

  static model.Transaction transactionFromRow(Map<String, Object?> r) =>
      model.Transaction(
        id: r['id'] as String,
        title: r['title'] as String,
        amount: (r['amount'] as num).toDouble(),
        date: DateTime.parse(r['date'] as String),
        isIncome: r['is_income'] == 1,
        category: r['category'] as String,
        account: r['account'] as String,
        recurrence: r['recurrence'] as String,
      );

  static Map<String, Object?> transactionRow(
    String username,
    model.Transaction tx,
  ) => {
    'id': tx.id,
    'username': username,
    'title': tx.title,
    'amount': tx.amount,
    'date': tx.date.toIso8601String(),
    'is_income': tx.isIncome ? 1 : 0,
    'category': tx.category,
    'account': tx.account,
    'recurrence': tx.recurrence,
  };

  static SavingsGoal goalFromRow(
    Map<String, Object?> r,
    List<GoalEntry> entries,
  ) => SavingsGoal(
    id: r['id'] as String,
    title: r['title'] as String,
    target: (r['target_amount'] as num).toDouble(),
    saved: (r['current_amount'] as num).toDouble(),
    color: Color(r['color'] as int),
    icon: resolveGoalIconByCodePoint(r['icon'] as int?),
    dueDate: r['due_date'] == null
        ? null
        : DateTime.parse(r['due_date'] as String),
    periodType: r['period_type'] as String? ?? 'monthly',
    isRecurring: r['is_recurring'] == 1,
    recurrence: r['recurrence'] as String? ?? 'none',
    isCompleted: r['is_completed'] == 1,
    isFailed: r['is_failed'] == 1,
    isArchived: r['is_archived'] == 1,
    createdAt: r['created_at'] == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(r['created_at'] as String),
    entries: entries,
  );

  static Map<String, Object?> goalRow(String username, SavingsGoal goal) => {
    'id': goal.id,
    'username': username,
    'title': goal.title,
    'target_amount': goal.target,
    'current_amount': goal.saved,
    'color': goal.color.toARGB32(),
    'icon': goal.icon.codePoint,
    'due_date': goal.dueDate?.toIso8601String(),
    'period_type': goal.periodType,
    'is_recurring': goal.isRecurring ? 1 : 0,
    'recurrence': goal.recurrence,
    'is_completed': goal.isCompleted ? 1 : 0,
    'is_failed': goal.isFailed ? 1 : 0,
    'is_archived': goal.isArchived ? 1 : 0,
    'created_at': goal.createdAt.toIso8601String(),
  };
}

/// Syncs additions/explicit edits and durable tombstones, never absence-based
/// deletes. A successfully committed chunk is checkpointed before the next one.
class LedgerSyncEngine {
  final SqliteLedgerStore local;
  final LedgerRemote remote;
  final void Function() checkSession;
  final void Function(int committed)? onProgress;
  LedgerSyncEngine(
    this.local,
    this.remote, {
    required this.checkSession,
    this.onProgress,
  });

  Future<bool> sync(String username) async {
    checkSession();
    final snapshot = await local.snapshot(username);
    checkSession();
    final cloud = await remote.read();
    checkSession();
    final writes = [...snapshot.pending];
    final dirty = {for (final w in writes) '${w.collection}/${w.id}'};
    // Migration/bootstrap only: import legacy local records missing remotely.
    // Remote copies (including tombstones) win over unedited stale local copies.
    for (final collection in SqliteLedgerStore.collections) {
      for (final record in snapshot.records[collection]!.entries) {
        if (!cloud[collection]!.containsKey(record.key) &&
            !dirty.contains('$collection/${record.key}')) {
          writes.add(
            LedgerWrite(collection, record.key, {
              ...record.value,
              '_deleted': false,
            }),
          );
        }
      }
    }
    var committed = 0;
    await commitBounded(
      remote,
      writes,
      checkSession,
      afterCommit: (chunk) async {
        await local.acknowledge(username, chunk);
        committed += chunk.length;
        onProgress?.call(committed);
      },
    );
    checkSession();
    final latest = await remote.read();
    checkSession();
    await local.applyRemote(username, latest, checkSession);
    checkSession();
    return (await local.snapshot(username)).pending.isEmpty;
  }

  Future<bool> restore(String username) async {
    checkSession();
    final snapshot = await local.snapshot(username);
    final cloud = await remote.read();
    checkSession();
    for (final collection in SqliteLedgerStore.collections) {
      for (final id in snapshot.records[collection]!.keys) {
        cloud[collection]!.putIfAbsent(id, () => {'id': id, '_deleted': true});
      }
    }
    final revision = snapshot.pending.fold<int>(
      0,
      (n, w) => w.revision! > n ? w.revision! : n,
    );
    await local.applyRemote(
      username,
      cloud,
      checkSession,
      discardPendingThrough: revision,
    );
    checkSession();
    return (await local.snapshot(username)).pending.isEmpty;
  }

  /// Deliberate user-selected replacement is the ONLY absence-based delete path.
  /// Multi-chunk replacements are resumable by rerunning; not globally atomic.
  Future<bool> overwrite(String username) async {
    checkSession();
    final snapshot = await local.snapshot(username);
    final cloud = await remote.read();
    checkSession();
    final pending = {
      for (final w in snapshot.pending) '${w.collection}/${w.id}': w,
    };
    final writes = <LedgerWrite>[];
    for (final collection in SqliteLedgerStore.collections) {
      final ids = {
        ...cloud[collection]!.keys,
        ...snapshot.records[collection]!.keys,
        ...snapshot.pending
            .where((w) => w.collection == collection)
            .map((w) => w.id),
      };
      for (final id in ids) {
        final data = snapshot.records[collection]![id];
        writes.add(
          LedgerWrite(
            collection,
            id,
            data == null
                ? {'id': id, '_deleted': true}
                : {...data, '_deleted': false},
            revision: pending['$collection/$id']?.revision,
          ),
        );
      }
    }
    await commitBounded(
      remote,
      writes,
      checkSession,
      afterCommit: (chunk) => local.acknowledge(username, chunk),
    );
    checkSession();
    return (await local.snapshot(username)).pending.isEmpty;
  }

  /// Conservative limits include both document count and encoded payload size.
  /// Firestore adds protocol/index overhead, so stay well below request limits.
  static Future<void> commitBounded(
    LedgerRemote remote,
    Iterable<LedgerWrite> writes,
    void Function() checkSession, {
    Future<void> Function(List<LedgerWrite>)? afterCommit,
  }) async {
    var chunk = <LedgerWrite>[];
    var bytes = 0;
    Future<void> flush() async {
      if (chunk.isEmpty) return;
      checkSession();
      await remote.commit(chunk);
      checkSession();
      await afterCommit?.call(chunk);
      chunk = [];
      bytes = 0;
    }

    for (final write in writes) {
      final size =
          utf8.encode(jsonEncode(write.data)).length +
          utf8.encode(write.id).length +
          256;
      if (size > 900000) {
        throw StateError(
          'Ledger record exceeds safe document size: ${write.id}',
        );
      }
      if (chunk.length >= 400 || bytes + size > 4 * 1024 * 1024) await flush();
      chunk.add(write);
      bytes += size;
    }
    await flush();
  }
}
