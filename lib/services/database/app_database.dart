import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/transaction.dart' as model;
import '../../models/savings_goal.dart';
import '../../models/user_profile.dart';
import 'security_helper.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance_vault.db');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE profiles (
            username TEXT PRIMARY KEY,
            display_name TEXT,
            bio TEXT,
            photo_path TEXT,
            primary_color INTEGER,
            secondary_color INTEGER,
            currency TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            is_income INTEGER NOT NULL,
            category TEXT NOT NULL,
            account TEXT NOT NULL,
            recurrence TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            category TEXT NOT NULL,
            amount_limit REAL NOT NULL,
            UNIQUE(username, category)
          )
        ''');

        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            title TEXT NOT NULL,
            target_amount REAL NOT NULL,
            current_amount REAL NOT NULL,
            color INTEGER NOT NULL,
            icon INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            name TEXT NOT NULL,
            UNIQUE(username, name)
          )
        ''');
      },
    );

    await _migrateLegacyPrefs(db);
    return db;
  }

  Future<void> _migrateLegacyPrefs(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersStr = prefs.getString('users');
      if (usersStr == null || usersStr.isEmpty) return;

      final Map<String, dynamic> legacyUsers = jsonDecode(usersStr);
      for (var entry in legacyUsers.entries) {
        final username = entry.key;
        final rawPassword = entry.value.toString();

        final existing = await db.query(
          'users',
          where: 'username = ?',
          whereArgs: [username],
        );

        if (existing.isEmpty) {
          final salt = SecurityHelper.generateSalt();
          final hash = SecurityHelper.hashPassword(rawPassword, salt);
          await db.insert('users', {
            'username': username,
            'password_hash': hash,
            'salt': salt,
            'created_at': DateTime.now().toIso8601String(),
          });

          await db.insert('profiles', {
            'username': username,
            'display_name': username,
            'bio': 'Personal Finance Explorer',
            'photo_path': null,
            'primary_color': const Color(0xFF8B5CF6).toARGB32(),
            'secondary_color': const Color(0xFF10B981).toARGB32(),
            'currency': prefs.getString('currency_$username') ?? '\$',
            'created_at': DateTime.now().toIso8601String(),
          });

          // Migrate legacy transactions
          final txStr = prefs.getString('tx_$username');
          if (txStr != null) {
            final List list = jsonDecode(txStr);
            for (var item in list) {
              await db.insert('transactions', {
                'id': item['id'] ?? UniqueKey().toString(),
                'username': username,
                'title': item['title'] ?? 'Transaction',
                'amount': (item['amount'] as num).toDouble(),
                'date': item['date'] ?? DateTime.now().toIso8601String(),
                'is_income': item['isIncome'] == true ? 1 : 0,
                'category': item['category'] ?? 'Other',
                'account': item['account'] ?? 'Main',
                'recurrence': item['recurrence'] ?? 'None',
              });
            }
          }

          // Migrate default accounts
          final accList = ['Main', 'Cash', 'Credit Card', 'Digital Wallet'];
          for (var acc in accList) {
            await db.insert(
              'accounts',
              {'username': username, 'name': acc},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          // Migrate default budgets
          final defaultBudgets = {
            'Food & Dining': 500.0,
            'Housing & Rent': 1500.0,
            'Transportation': 300.0,
            'Entertainment': 200.0,
          };
          for (var b in defaultBudgets.entries) {
            await db.insert(
              'budgets',
              {'username': username, 'category': b.key, 'amount_limit': b.value},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Legacy migration note: $e');
    }
  }

  // --- AUTHENTICATION ---
  Future<bool> registerUser(String username, String password) async {
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (existing.isNotEmpty) return false;

    final salt = SecurityHelper.generateSalt();
    final hash = SecurityHelper.hashPassword(password, salt);

    await db.insert('users', {
      'username': username,
      'password_hash': hash,
      'salt': salt,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('profiles', {
      'username': username,
      'display_name': username,
      'bio': 'Managing finances with clarity & style.',
      'photo_path': null,
      'primary_color': const Color(0xFF8B5CF6).toARGB32(),
      'secondary_color': const Color(0xFF10B981).toARGB32(),
      'currency': '\$',
      'created_at': DateTime.now().toIso8601String(),
    });

    for (var acc in ['Main', 'Cash', 'Credit Card', 'Digital Wallet']) {
      await db.insert('accounts', {'username': username, 'name': acc});
    }

    final defaultBudgets = {
      'Food & Dining': 500.0,
      'Housing & Rent': 1500.0,
      'Transportation': 300.0,
      'Entertainment': 200.0,
    };
    for (var b in defaultBudgets.entries) {
      await db.insert('budgets', {
        'username': username,
        'category': b.key,
        'amount_limit': b.value,
      });
    }

    return true;
  }

  Future<bool> authenticateUser(String username, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (results.isEmpty) return false;

    final user = results.first;
    final salt = user['salt'] as String;
    final expectedHash = user['password_hash'] as String;

    return SecurityHelper.verifyPassword(password, salt, expectedHash);
  }

  Future<bool> changePassword(String username, String currentPassword, String newPassword) async {
    final auth = await authenticateUser(username, currentPassword);
    if (!auth) return false;

    final db = await database;
    final newSalt = SecurityHelper.generateSalt();
    final newHash = SecurityHelper.hashPassword(newPassword, newSalt);

    final count = await db.update(
      'users',
      {'password_hash': newHash, 'salt': newSalt},
      where: 'username = ?',
      whereArgs: [username],
    );
    return count > 0;
  }

  // --- PROFILE ---
  Future<UserProfile> loadProfile(String username) async {
    final db = await database;
    final results = await db.query(
      'profiles',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (results.isNotEmpty) {
      return UserProfile.fromMap(results.first);
    }

    final profile = UserProfile(username: username, displayName: username);
    await saveProfile(profile);
    return profile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- TRANSACTIONS ---
  Future<List<model.Transaction>> loadTransactions(String username) async {
    final db = await database;
    final results = await db.query(
      'transactions',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'date DESC',
    );

    return results.map((row) {
      return model.Transaction(
        id: row['id'] as String?,
        title: row['title'] as String,
        amount: (row['amount'] as num).toDouble(),
        date: DateTime.parse(row['date'] as String),
        isIncome: (row['is_income'] as int) == 1,
        category: row['category'] as String,
        account: row['account'] as String,
        recurrence: row['recurrence'] as String,
      );
    }).toList();
  }

  Future<void> saveTransactions(String username, List<model.Transaction> txs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'username = ?', whereArgs: [username]);
      for (var tx in txs) {
        await txn.insert('transactions', {
          'id': tx.id,
          'username': username,
          'title': tx.title,
          'amount': tx.amount,
          'date': tx.date.toIso8601String(),
          'is_income': tx.isIncome ? 1 : 0,
          'category': tx.category,
          'account': tx.account,
          'recurrence': tx.recurrence,
        });
      }
    });
  }

  // --- BUDGETS ---
  Future<Map<String, double>> loadBudgets(String username) async {
    final db = await database;
    final results = await db.query(
      'budgets',
      where: 'username = ?',
      whereArgs: [username],
    );

    final map = <String, double>{};
    for (var r in results) {
      map[r['category'] as String] = (r['amount_limit'] as num).toDouble();
    }
    return map.isNotEmpty ? map : {
      'Food & Dining': 500.0,
      'Housing & Rent': 1500.0,
      'Transportation': 300.0,
      'Entertainment': 200.0,
    };
  }

  Future<void> saveBudgets(String username, Map<String, double> budgets) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('budgets', where: 'username = ?', whereArgs: [username]);
      for (var entry in budgets.entries) {
        await txn.insert('budgets', {
          'username': username,
          'category': entry.key,
          'amount_limit': entry.value,
        });
      }
    });
  }

  // --- GOALS ---
  Future<List<SavingsGoal>> loadGoals(String username) async {
    final db = await database;
    final results = await db.query(
      'goals',
      where: 'username = ?',
      whereArgs: [username],
    );

    return results.map((r) {
      return SavingsGoal(
        id: r['id'] as String?,
        title: r['title'] as String,
        target: (r['target_amount'] as num).toDouble(),
        saved: (r['current_amount'] as num).toDouble(),
        color: Color(r['color'] as int),
        icon: resolveGoalIconByCodePoint(r['icon'] as int?),
      );
    }).toList();
  }

  Future<void> saveGoals(String username, List<SavingsGoal> goals) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('goals', where: 'username = ?', whereArgs: [username]);
      for (var g in goals) {
        await txn.insert('goals', {
          'id': g.id,
          'username': username,
          'title': g.title,
          'target_amount': g.target,
          'current_amount': g.saved,
          'color': g.color.toARGB32(),
          'icon': g.icon.codePoint,
        });
      }
    });
  }

  // --- ACCOUNTS ---
  Future<List<String>> loadAccounts(String username) async {
    final db = await database;
    final results = await db.query(
      'accounts',
      where: 'username = ?',
      whereArgs: [username],
    );
    final list = results.map((r) => r['name'] as String).toList();
    return list.isNotEmpty ? list : ['Main', 'Cash', 'Credit Card', 'Digital Wallet'];
  }

  Future<void> saveAccounts(String username, List<String> accounts) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('accounts', where: 'username = ?', whereArgs: [username]);
      for (var acc in accounts) {
        await txn.insert('accounts', {'username': username, 'name': acc});
      }
    });
  }

  // --- FULL SQL EXPORT ---
  Future<String> exportToSql(String username) async {
    final db = await database;
    final buffer = StringBuffer();
    final now = DateTime.now().toIso8601String();

    buffer.writeln('-- ========================================================');
    buffer.writeln('-- Balance Tracker SQL Ledger Backup');
    buffer.writeln('-- User: $username');
    buffer.writeln('-- Export Date: $now');
    buffer.writeln('-- ========================================================\n');

    buffer.writeln('BEGIN TRANSACTION;\n');

    // Profile
    final profiles = await db.query('profiles', where: 'username = ?', whereArgs: [username]);
    if (profiles.isNotEmpty) {
      final p = profiles.first;
      buffer.writeln('-- User Profile');
      buffer.writeln(
        "INSERT INTO profiles (username, display_name, bio, photo_path, primary_color, secondary_color, currency, created_at) "
        "VALUES ('${p['username']}', '${p['display_name']}', '${p['bio']}', '${p['photo_path']}', ${p['primary_color']}, ${p['secondary_color']}, '${p['currency']}', '${p['created_at']}');\n",
      );
    }

    // Accounts
    final accounts = await db.query('accounts', where: 'username = ?', whereArgs: [username]);
    if (accounts.isNotEmpty) {
      buffer.writeln('-- Accounts & Wallets');
      for (var a in accounts) {
        buffer.writeln("INSERT INTO accounts (username, name) VALUES ('$username', '${a['name']}');");
      }
      buffer.writeln();
    }

    // Budgets
    final budgets = await db.query('budgets', where: 'username = ?', whereArgs: [username]);
    if (budgets.isNotEmpty) {
      buffer.writeln('-- Monthly Budgets');
      for (var b in budgets) {
        buffer.writeln("INSERT INTO budgets (username, category, amount_limit) VALUES ('$username', '${b['category']}', ${b['amount_limit']});");
      }
      buffer.writeln();
    }

    // Goals
    final goals = await db.query('goals', where: 'username = ?', whereArgs: [username]);
    if (goals.isNotEmpty) {
      buffer.writeln('-- Savings Goals');
      for (var g in goals) {
        buffer.writeln("INSERT INTO goals (id, username, title, target_amount, current_amount, color, icon) VALUES ('${g['id']}', '$username', '${g['title']}', ${g['target_amount']}, ${g['current_amount']}, ${g['color']}, ${g['icon']});");
      }
      buffer.writeln();
    }

    // Transactions
    final txs = await db.query('transactions', where: 'username = ?', whereArgs: [username], orderBy: 'date ASC');
    if (txs.isNotEmpty) {
      buffer.writeln('-- Transactions');
      for (var t in txs) {
        final title = (t['title'] as String).replaceAll("'", "''");
        buffer.writeln(
          "INSERT INTO transactions (id, username, title, amount, date, is_income, category, account, recurrence) "
          "VALUES ('${t['id']}', '$username', '$title', ${t['amount']}, '${t['date']}', ${t['is_income']}, '${t['category']}', '${t['account']}', '${t['recurrence']}');",
        );
      }
      buffer.writeln();
    }

    buffer.writeln('COMMIT;\n');
    return buffer.toString();
  }
}
