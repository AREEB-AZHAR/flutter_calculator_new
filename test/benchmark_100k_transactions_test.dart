// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_tracker/models/transaction.dart' as model;

import 'package:path/path.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('100,000 Transactions Stress & Scalability Benchmark', () {
    test('Evaluate 100,000 transactions query, memory, and calculation latency', () async {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'benchmark_vault.db');
      await deleteDatabase(path);

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE transactions (
              id TEXT PRIMARY KEY,
              username TEXT,
              title TEXT,
              amount REAL,
              date TEXT,
              is_income INTEGER,
              category TEXT,
              account TEXT,
              recurrence TEXT
            )
          ''');
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_transactions_username_date 
            ON transactions(username, date DESC)
          ''');
        },
      );

      const testUser = 'benchmark_user_100k';

      print('\n🚀 STARTING 100,000 TRANSACTIONS STRESS BENCHMARK 🚀');

      // 1. Bulk insert 100,000 records using fast SQLite transaction batching
      final insertStopwatch = Stopwatch()..start();
      final batchSize = 5000;
      final now = DateTime.now();

      for (int i = 0; i < 100000; i += batchSize) {
        await db.transaction((txn) async {
          final batch = txn.batch();
          for (int j = 0; j < batchSize; j++) {
            final idx = i + j;
            final isIncome = idx % 3 == 0;
            final date = now.subtract(Duration(minutes: idx * 5));
            batch.insert('transactions', {
              'id': 'tx_100k_$idx',
              'username': testUser,
              'title': 'Transaction $idx Title Groceries Salary',
              'amount': (idx % 500) + 10.5,
              'date': date.toIso8601String(),
              'is_income': isIncome ? 1 : 0,
              'category': (idx % 2 == 0) ? 'Food & Dining' : 'Transportation',
              'account': 'Main',
              'recurrence': 'None',
            });
          }
          await batch.commit(noResult: true);
        });
      }
      insertStopwatch.stop();
      print('⏱️ 100,000 Records Bulk Insertion Time: ${insertStopwatch.elapsedMilliseconds} ms (${(insertStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s)');

      // 2. Measure Query & Object Mapping Latency with index
      final queryStopwatch = Stopwatch()..start();
      final maps = await db.query(
        'transactions',
        where: 'username = ?',
        whereArgs: [testUser],
        orderBy: 'date DESC',
      );
      final results = maps.map((row) {
        return model.Transaction(
          id: row['id'] as String?,
          title: row['title'] as String,
          amount: (row['amount'] as num).toDouble(),
          date: DateTime.parse(row['date'] as String),
          isIncome: (row['is_income'] as int) == 1,
          category: (row['category'] as String?) ?? 'Other',
          account: (row['account'] as String?) ?? 'Main',
          recurrence: (row['recurrence'] as String?) ?? 'None',
        );
      }).toList();
      queryStopwatch.stop();
      print('⏱️ 100,000 Records SQLite Query & In-Memory Deserialization: ${queryStopwatch.elapsedMilliseconds} ms');
      expect(results.length, 100000);

      // 3. Measure UI Computations (Total Balance Fold across 100,000 items)
      final balanceStopwatch = Stopwatch()..start();
      final totalBalance = results.fold(0.0, (sum, t) => t.isIncome ? sum + t.amount : sum - t.amount);
      balanceStopwatch.stop();
      print('⏱️ 100,000 Records Cumulative Balance Calculation (.fold): ${balanceStopwatch.elapsedMilliseconds} ms (Balance: \$${totalBalance.toStringAsFixed(2)})');

      // 4. Measure Search / Filter Latency across 100,000 items
      final filterStopwatch = Stopwatch()..start();
      final filtered = results.where((t) {
        return t.title.toLowerCase().contains('groceries') && !t.isIncome;
      }).toList();
      filterStopwatch.stop();
      print('⏱️ 100,000 Records In-Memory Search & Filter (.where): ${filterStopwatch.elapsedMilliseconds} ms (Found: ${filtered.length} matches)');

      // 5. Measure Single Transaction Atomic Insert
      final singleInsertStopwatch = Stopwatch()..start();
      final newTx = model.Transaction(
        id: 'tx_single_new',
        title: 'Single Coffee',
        amount: 4.50,
        date: DateTime.now(),
        isIncome: false,
        category: 'Food & Dining',
        account: 'Main',
        recurrence: 'None',
      );
      await db.insert('transactions', {
        'id': newTx.id,
        'username': testUser,
        'title': newTx.title,
        'amount': newTx.amount,
        'date': newTx.date.toIso8601String(),
        'is_income': newTx.isIncome ? 1 : 0,
        'category': newTx.category,
        'account': newTx.account,
        'recurrence': newTx.recurrence,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      singleInsertStopwatch.stop();
      print('⏱️ Atomic Single Transaction Insert (.insertTransaction): ${singleInsertStopwatch.elapsedMilliseconds} ms');

      // Clean up benchmark database
      await db.close();
      await deleteDatabase(path);
      print('✅ 100,000 Transactions Benchmark Completed Successfully!\n');
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
