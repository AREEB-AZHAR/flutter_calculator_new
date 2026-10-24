import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/transaction.dart' as model;
import '../models/savings_goal.dart';

/// Compare financial content, not server timestamps, map order or JSON numbers.
String syncFingerprint(
  String collection,
  String id,
  Map<String, dynamic> data,
) {
  if (data['_deleted'] == true) return _digest({'_deleted': true});
  Map<String, dynamic> payload;
  if (collection == 'transactions') {
    payload = model.Transaction.fromJson({...data, 'id': id}).toJson();
  } else if (collection == 'goals') {
    payload = SavingsGoal.fromJson({
      ...data,
      'id': id,
      'createdAt': data['createdAt'] ?? '1970-01-01T00:00:00.000Z',
      'entries': [
        for (final entry in (data['entries'] as List? ?? []))
          {
            ...(entry as Map<String, dynamic>),
            'createdAt':
                entry['createdAt'] ??
                entry['date'] ??
                '1970-01-01T00:00:00.000Z',
          },
      ],
    }).toJson();
    (payload['entries'] as List).sort(
      (dynamic a, dynamic b) =>
          (a['id'] as String).compareTo(b['id'] as String),
    );
  } else {
    payload = {...data}
      ..remove('_updatedAt')
      ..remove('updatedAt')
      ..remove('lastSyncedAt')
      ..remove('platform');
  }
  return _digest(payload);
}

String _digest(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  if (value is num) return value.toDouble();
  return value;
}

class LedgerConflict {
  final String collection;
  final String id;
  const LedgerConflict(this.collection, this.id);
}

List<LedgerConflict> findLedgerConflicts({
  required Map<String, Map<String, Map<String, dynamic>>> local,
  required Map<String, Map<String, Map<String, dynamic>>> cloud,
  required Map<String, Map<String, dynamic>> pending,
  required Map<String, Map<String, String>> baselines,
}) {
  final conflicts = <LedgerConflict>[];
  for (final collection in ['transactions', 'goals']) {
    for (final entry in cloud[collection]!.entries) {
      final key = '$collection/${entry.key}';
      final queued = pending[key];
      final device = queued ?? local[collection]![entry.key];
      if (device == null) continue; // New cloud record, not a conflict.
      final deviceHash = syncFingerprint(collection, entry.key, device);
      final cloudHash = syncFingerprint(collection, entry.key, entry.value);
      if (deviceHash == cloudHash) continue;
      if (entry.value['_deleted'] == true && queued == null) continue;
      final base = baselines[collection]?[entry.key];
      if (base != null && deviceHash == base) continue; // Only cloud changed.
      if (queued != null && base != null && cloudHash == base) {
        continue; // Offline edit.
      }
      // No common version, both changed, or an untracked local modification.
      conflicts.add(LedgerConflict(collection, entry.key));
    }
  }
  return conflicts;
}
