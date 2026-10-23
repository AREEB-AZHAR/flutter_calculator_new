import 'dart:convert';
import 'dart:math' show min;
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/planned_transaction.dart';
import 'ledger_sync.dart';

class ProcessedPlan {
  final PlannedTransaction plan;
  final PlannedTransaction? next;
  const ProcessedPlan(this.plan, this.next);
}

/// The occurrence, its processed flag, successor and sync outbox commit together.
/// Notifications and widget state must be published only after this returns.
class AtomicPlans {
  final Database db;
  const AtomicPlans(this.db);

  Future<ProcessedPlan?> process(
    String username,
    String id, {
    required DateTime now,
    bool force = false,
  }) => db.transaction((txn) async {
    final rows = await txn.query(
      'planned_transactions',
      where: 'username = ? AND id = ? AND is_processed = 0',
      whereArgs: [username, id],
    );
    if (rows.isEmpty) return null;
    final plan = PlannedTransaction.fromJson(rows.single);
    // Plans are day-based: every occurrence dated today is due, including those
    // later today. Preserve the app's existing policy without a 23:59:59 gap.
    final tomorrow = (now.isUtc ? DateTime.utc : DateTime.new)(
      now.year,
      now.month,
      now.day + 1,
    );
    if (!force && !plan.date.isBefore(tomorrow)) return null;
    final existing = await txn.query(
      'transactions',
      columns: ['username'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existing.isNotEmpty && existing.single['username'] != username) {
      throw StateError('Occurrence ID belongs to another account');
    }
    // Stable occurrence ID plus atomic processed check makes retries/concurrent
    // invocations idempotent. Never replace a previously recorded occurrence.
    await txn.insert(
      'transactions',
      SqliteLedgerStore.transactionRow(username, plan.toActiveTransaction()),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await txn.update(
      'planned_transactions',
      {'is_processed': 1},
      where: 'username = ? AND id = ?',
      whereArgs: [username, id],
    );
    final next = successor(plan);
    if (next != null) {
      final owners = await txn.query(
        'planned_transactions',
        columns: ['username'],
        where: 'id = ?',
        whereArgs: [next.id],
      );
      if (owners.isNotEmpty && owners.single['username'] != username) {
        throw StateError('Successor belongs to another account');
      }
      await txn.insert(
        'planned_transactions',
        row(username, next),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    return ProcessedPlan(plan, next);
  });

  /// Bounded catch-up. Any remaining backlog stays unprocessed for the next pass.
  Future<List<ProcessedPlan>> processDue(
    String username, {
    required DateTime now,
    int limit = 1000,
  }) async {
    final results = <ProcessedPlan>[];
    final tomorrow = (now.isUtc ? DateTime.utc : DateTime.new)(
      now.year,
      now.month,
      now.day + 1,
    );
    final candidates =
        (await db.query(
              'planned_transactions',
              where: 'username = ? AND is_processed = 0',
              whereArgs: [username],
              orderBy: 'date ASC, id ASC',
            ))
            .map(PlannedTransaction.fromJson)
            .where((p) => p.date.isBefore(tomorrow))
            .toList();
    for (var i = 0; i < candidates.length && results.length < limit; i++) {
      final result = await process(username, candidates[i].id, now: now);
      if (result == null) {
        continue; // Another caller already processed/deleted it.
      }
      results.add(result);
      if (result.next != null && result.next!.date.isBefore(tomorrow)) {
        candidates.add(result.next!);
      }
    }
    return results;
  }

  static PlannedTransaction? successor(PlannedTransaction plan) {
    final d = plan.date;
    final anchorDay = plan.anchorDay ?? d.day;
    final anchorMonth = plan.anchorMonth ?? d.month;
    DateTime date(int year, int month, int day) =>
        (d.isUtc ? DateTime.utc : DateTime.new)(
          year,
          month,
          day,
          d.hour,
          d.minute,
          d.second,
          d.millisecond,
          d.microsecond,
        );
    DateTime next;
    switch (plan.recurrence) {
      case 'None':
        return null;
      case 'Daily':
        next = date(d.year, d.month, d.day + 1);
      case 'Weekly':
        next = date(d.year, d.month, d.day + 7);
      case 'Monthly':
        final month = date(d.year, d.month + 1, 1);
        next = date(
          month.year,
          month.month,
          min(anchorDay, date(month.year, month.month + 1, 0).day),
        );
      case 'Yearly':
        next = date(
          d.year + 1,
          anchorMonth,
          min(anchorDay, date(d.year + 1, anchorMonth + 1, 0).day),
        );
      default:
        throw StateError('Unsupported recurrence: ${plan.recurrence}');
    }
    final id = 'plan_${sha256.convert(utf8.encode('next:${plan.id}'))}';
    return plan.copyWith(
      id: id,
      date: next,
      isProcessed: false,
      anchorDay: anchorDay,
      anchorMonth: anchorMonth,
    );
  }

  static Map<String, Object?> row(String username, PlannedTransaction plan) => {
    'id': plan.id,
    'username': username,
    'title': plan.title,
    'amount': plan.amount,
    'date': plan.date.toIso8601String(),
    'is_income': plan.isIncome ? 1 : 0,
    'category': plan.category,
    'account': plan.account,
    'recurrence': plan.recurrence,
    'is_processed': plan.isProcessed ? 1 : 0,
    'created_at': plan.createdAt.toIso8601String(),
    'anchor_day': plan.anchorDay,
    'anchor_month': plan.anchorMonth,
  };
}
