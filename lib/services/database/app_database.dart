import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/transaction.dart' as model;
import '../../models/savings_goal.dart';
import '../../models/goal_entry.dart';
import '../../models/user_profile.dart';
import '../../models/loan.dart';
import '../../models/planned_transaction.dart';
import '../../models/saved_account_info.dart';
import '../biometric_service.dart';
import 'security_helper.dart';
import '../ledger_sync.dart';
import '../atomic_plans.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;

  Future<Database>? _opening;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    _opening = null;
    await db?.close();
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    try {
      return _database = await (_opening ??= _initDatabase());
    } catch (_) {
      _opening = null;
      rethrow;
    }
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
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await SqliteLedgerStore.install(db);
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL COLLATE NOCASE,
            email TEXT COLLATE NOCASE,
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
            text_color INTEGER,
            theme TEXT,
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

    // Ensure email column exists on users table
    try {
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT COLLATE NOCASE');
    } catch (_) {}

    // Ensure case-insensitive indexes exist for rapid authentication and lookup
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_username_nocase ON users(username COLLATE NOCASE)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email_nocase ON users(email COLLATE NOCASE)');
    } catch (_) {}

    // Ensure text_color and theme columns exist for existing databases
    try {
      await db.execute('ALTER TABLE profiles ADD COLUMN text_color INTEGER');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE profiles ADD COLUMN theme TEXT');
    } catch (_) {}

    // Ensure loans table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS loans (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          title TEXT NOT NULL,
          person_name TEXT NOT NULL,
          amount REAL NOT NULL,
          due_date TEXT NOT NULL,
          type TEXT NOT NULL,
          is_settled INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          account TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}

    // Ensure planned_transactions table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS planned_transactions (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          is_income INTEGER NOT NULL,
          category TEXT NOT NULL,
          account TEXT NOT NULL,
          recurrence TEXT NOT NULL,
          is_processed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}

    // Ensure index on transactions exists for 100k+ scalability
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_username_date ON transactions(username, date DESC)');
    } catch (_) {}

    // --- Enhanced Goals: migrate goals table with new columns ---
    for (final col in [
      'ALTER TABLE goals ADD COLUMN due_date TEXT',
      'ALTER TABLE goals ADD COLUMN period_type TEXT DEFAULT \'monthly\'',
      'ALTER TABLE goals ADD COLUMN is_recurring INTEGER DEFAULT 0',
      'ALTER TABLE goals ADD COLUMN recurrence TEXT DEFAULT \'none\'',
      'ALTER TABLE goals ADD COLUMN is_completed INTEGER DEFAULT 0',
      'ALTER TABLE goals ADD COLUMN is_failed INTEGER DEFAULT 0',
      'ALTER TABLE goals ADD COLUMN is_archived INTEGER DEFAULT 0',
      'ALTER TABLE goals ADD COLUMN created_at TEXT',
    ]) {
      try {
        await db.execute(col);
      } catch (_) {}
    }

    // --- Goal Entries table for tracking individual deposits ---
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goal_entries (
          id TEXT PRIMARY KEY,
          goal_id TEXT NOT NULL,
          username TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_entries_goal ON goal_entries(goal_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_entries_user ON goal_entries(username)');
    } catch (_) {}


    // Version 2 additions are idempotent for fresh installs and legacy databases.
    final planColumns = await db.rawQuery(
      'PRAGMA table_info(planned_transactions)',
    );
    for (final name in ['anchor_day', 'anchor_month']) {
      if (!planColumns.any((c) => c['name'] == name)) {
        await db.execute(
          'ALTER TABLE planned_transactions ADD COLUMN $name INTEGER',
        );
      }
    }
    await SqliteLedgerStore.install(db);
    await _migrateLegacyPrefs(db);
    return db;
  }

  Future<void> _migrateLegacyPrefs(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('legacy_prefs_migrated') == true) return;

      final usersStr = prefs.getString('users');
      if (usersStr == null || usersStr.isEmpty) {
        await prefs.setBool('legacy_prefs_migrated', true);
        return;
      }

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
            await db.insert('accounts', {
              'username': username,
              'name': acc,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }

          // Migrate default budgets
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
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }

      // Mark migration completed and clear legacy user map so it never resurrects deleted accounts
      await prefs.remove('users');
      await prefs.setBool('legacy_prefs_migrated', true);
    } catch (e) {
      debugPrint('Legacy migration note: $e');
    }
  }

  // --- AUTHENTICATION ---
  Future<bool> registerUser({
    required String username,
    required String password,
    String? email,
  }) async {
    final db = await database;
    final cleanUsername = username.trim();
    final existing = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE',
      whereArgs: [cleanUsername],
    );
    if (existing.isNotEmpty) return false;

    if (email != null && email.trim().isNotEmpty) {
      final cleanEmail = email.trim().toLowerCase();
      final existingEmail = await db.query(
        'users',
        where: 'email = ? COLLATE NOCASE',
        whereArgs: [cleanEmail],
      );
      if (existingEmail.isNotEmpty) return false;
    }

    final salt = SecurityHelper.generateSalt();
    final hash = SecurityHelper.hashPassword(password, salt);

    await db.insert('users', {
      'username': cleanUsername,
      'email': email?.trim().toLowerCase(),
      'password_hash': hash,
      'salt': salt,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('profiles', {
      'username': cleanUsername,
      'display_name': cleanUsername,
      'bio': 'Managing finances with clarity & style.',
      'photo_path': null,
      'primary_color': const Color(0xFFE4572E).toARGB32(),
      'secondary_color': const Color(0xFFF6F0E1).toARGB32(),
      'text_color': null,
      'theme': 'Ledger',
      'currency': '\$',
      'created_at': DateTime.now().toIso8601String(),
    });

    for (var acc in ['Main', 'Cash', 'Credit Card', 'Digital Wallet']) {
      await db.insert('accounts', {'username': cleanUsername, 'name': acc});
    }

    final defaultBudgets = {
      'Food & Dining': 500.0,
      'Housing & Rent': 1500.0,
      'Transportation': 300.0,
      'Entertainment': 200.0,
    };
    for (var b in defaultBudgets.entries) {
      await db.insert('budgets', {
        'username': cleanUsername,
        'category': b.key,
        'amount_limit': b.value,
      });
    }

    return true;
  }

  Future<bool> authenticateUser(String identifier, String password) async {
    final db = await database;
    final cleanId = identifier.trim();
    final results = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE OR email = ? COLLATE NOCASE',
      whereArgs: [cleanId, cleanId],
    );
    if (results.isEmpty) return false;

    final user = results.first;
    final salt = user['salt'] as String;
    final expectedHash = user['password_hash'] as String;

    return SecurityHelper.verifyPassword(password, salt, expectedHash);
  }

  /// Resolves the actual canonical username for either a username or a bound email identifier.
  Future<String?> getUsernameForIdentifier(String identifier) async {
    final db = await database;
    final cleanId = identifier.trim();
    final results = await db.query(
      'users',
      columns: ['username'],
      where: 'username = ? COLLATE NOCASE OR email = ? COLLATE NOCASE',
      whereArgs: [cleanId, cleanId],
    );
    if (results.isNotEmpty) {
      return results.first['username'] as String;
    }
    return null;
  }

  /// Retrieves the bound email for a given user.
  Future<String?> getUserEmail(String username) async {
    final db = await database;
    final cleanUsername = username.trim();
    final results = await db.query(
      'users',
      columns: ['email'],
      where: 'username = ? COLLATE NOCASE',
      whereArgs: [cleanUsername],
    );
    if (results.isNotEmpty) {
      return results.first['email'] as String?;
    }
    return null;
  }

  /// Binds or updates a recovery email address for a user.
  Future<bool> bindEmailToUser(String username, String email) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim();
    final existing = await db.query(
      'users',
      where: 'email = ? COLLATE NOCASE AND username != ? COLLATE NOCASE',
      whereArgs: [cleanEmail, cleanUsername],
    );
    if (existing.isNotEmpty) return false;

    final count = await db.update(
      'users',
      {'email': cleanEmail},
      where: 'username = ? COLLATE NOCASE',
      whereArgs: [cleanUsername],
    );
    return count > 0;
  }

  /// Looks up a user account by email address or username.
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final cleanEmail = email.trim();
    final results = await db.query(
      'users',
      where: 'email = ? COLLATE NOCASE OR username = ? COLLATE NOCASE',
      whereArgs: [cleanEmail, cleanEmail],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Updates a user's password using their bound email address (for password recovery).
  Future<bool> updatePasswordByEmail(String email, String newPassword) async {
    final db = await database;
    final cleanEmail = email.trim();
    final newSalt = SecurityHelper.generateSalt();
    final newHash = SecurityHelper.hashPassword(newPassword, newSalt);

    final count = await db.update(
      'users',
      {'password_hash': newHash, 'salt': newSalt},
      where: 'email = ? COLLATE NOCASE OR username = ? COLLATE NOCASE',
      whereArgs: [cleanEmail, cleanEmail],
    );
    return count > 0;
  }

  /// Changes only the verified local vault if its credentials have not changed.
  Future<bool> updateRecoveredPassword({required String username, required String email,
      required String expectedHash, required String newPassword}) async {
    final db = await database;
    final salt = SecurityHelper.generateSalt();
    // Compare-and-swap exactly the verified local account; never reset all rows
    // matching an email-or-username expression, or a rebound email/account.
    return await db.update('users', {'password_hash': SecurityHelper.hashPassword(newPassword, salt), 'salt': salt},
      where: 'username = ? COLLATE NOCASE AND email = ? COLLATE NOCASE AND password_hash = ?',
      whereArgs: [username, email, expectedHash]) == 1;
  }

  /// Checks if a username or email has existing transactions or goals in the local SQLite database.
  Future<bool> hasUserData(String username) async {
    final db = await database;
    final txRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM transactions WHERE username = ?',
      [username],
    );
    final txCount = txRes.isNotEmpty ? (txRes.first['c'] as int? ?? 0) : 0;

    final goalsRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM goals WHERE username = ?',
      [username],
    );
    final goalsCount = goalsRes.isNotEmpty
        ? (goalsRes.first['c'] as int? ?? 0)
        : 0;
    return txCount > 0 || goalsCount > 0;
  }

  /// Retrieves all saved user accounts remembered on this device.
  Future<List<SavedAccountInfo>> getAllSavedAccounts() async {
    final db = await database;
    try {
      final rows = await db.rawQuery('''
        SELECT 
          u.username,
          u.email,
          u.created_at,
          p.display_name,
          p.photo_path,
          p.primary_color
        FROM users u
        LEFT JOIN profiles p ON u.username = p.username
        ORDER BY u.id DESC
      ''');

      final List<SavedAccountInfo> result = [];
      for (final r in rows) {
        final username = r['username'] as String;
        final email = r['email'] as String?;
        final displayName = (r['display_name'] as String?)?.isNotEmpty == true
            ? r['display_name'] as String
            : username;
        final photoPath = r['photo_path'] as String?;
        final primaryColor = (r['primary_color'] as int?) ?? const Color(0xFFE4572E).toARGB32();
        final createdAt = r['created_at'] as String?;

        final isBio = await BiometricService.isBiometricEnabled(username: username);
        final isGoogle = (email != null && email.contains('@') && username == email);

        result.add(SavedAccountInfo(
          username: username,
          email: email,
          displayName: displayName,
          photoPath: photoPath,
          primaryColor: primaryColor,
          isBiometricEnabled: isBio,
          isGoogleAccount: isGoogle,
          createdAt: createdAt,
        ));
      }
      return result;
    } catch (e) {
      debugPrint('AppDatabase.getAllSavedAccounts error: $e');
      return [];
    }
  }

  /// Removes a saved user account and all its data and settings from this device.
  Future<bool> deleteSavedAccount(String username) async {
    final db = await database;
    try {
      // 1. Cascading SQLite wipe of all records tied to this username
      await db.transaction((txn) async {
        await txn.delete('users', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('profiles', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('transactions', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('accounts', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('budgets', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('goals', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('goal_entries', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('loans', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
        await txn.delete('planned_transactions', where: 'username = ? COLLATE NOCASE', whereArgs: [username]);
      });

      // 2. Clear any lingering SharedPreferences caches for this user
      try {
        final prefs = await SharedPreferences.getInstance();

        // Remove from legacy SharedPreferences users JSON if present
        final usersStr = prefs.getString('users');
        if (usersStr != null && usersStr.isNotEmpty) {
          try {
            final Map<String, dynamic> legacyUsers = jsonDecode(usersStr);
            legacyUsers.removeWhere((k, v) => k.toLowerCase() == username.toLowerCase());
            if (legacyUsers.isEmpty) {
              await prefs.remove('users');
            } else {
              await prefs.setString('users', jsonEncode(legacyUsers));
            }
          } catch (_) {}
        }
        await prefs.setBool('legacy_prefs_migrated', true);

        // Biometric / Last login preferences
        final lastUser = prefs.getString('tally_last_logged_in_user');
        if (lastUser != null && lastUser.toLowerCase() == username.toLowerCase()) {
          await prefs.remove('tally_last_logged_in_user');
        }
        final bioUser = prefs.getString('tally_biometric_username');
        if (bioUser != null && bioUser.toLowerCase() == username.toLowerCase()) {
          await prefs.remove('tally_biometric_username');
          await prefs.setBool('tally_biometric_enabled', false);
        }
        await prefs.remove('tally_biometric_enabled_$username');
        await prefs.remove('tally_biometric_prompted_$username');

        // Google Auth cache
        final googleEmail = prefs.getString('tally_last_google_email');
        if (googleEmail != null && googleEmail.toLowerCase() == username.toLowerCase()) {
          await prefs.remove('tally_last_google_email');
          await prefs.remove('tally_last_google_name');
        }

        // Ledger & Theme preferences
        await prefs.remove('tx_$username');
        await prefs.remove('currency_$username');
        await prefs.remove('tally_reminders_enabled_$username');
        await prefs.remove('tally_theme_$username');
        await prefs.remove('tally_primary_color_$username');
        await prefs.remove('tally_secondary_color_$username');
        await prefs.remove('tally_text_color_$username');
        await prefs.remove('tally_currency_$username');
        await prefs.remove('has_seen_tour_$username');
        await prefs.remove('tally_theme_passes_$username');
        await prefs.remove('tally_pro_unlocked_$username');
        await prefs.remove('tally_ads_removed_$username');
        await prefs.remove('tally_pro_trial_expiry_$username');
      } catch (pe) {
        debugPrint('deleteSavedAccount prefs cleanup notice: $pe');
      }

      return true;
    } catch (e) {
      debugPrint('AppDatabase.deleteSavedAccount error: $e');
      return false;
    }
  }

  /// Migrates all ledger data (transactions, accounts, budgets, goals, and profile)
  /// from an existing local account to a bound Google account.
  Future<void> migrateAndMergeUserData({
    required String fromUsername,
    required String toUsername,
    required bool mergeWithExisting,
  }) async {
    if (fromUsername == toUsername) return;
    final db = await database;

    await db.transaction((txn) async {
      // 1. Transactions
      final fromTx = await txn.query(
        'transactions',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      for (var tx in fromTx) {
        final txMap = Map<String, dynamic>.from(tx);
        txMap['username'] = toUsername;
        await txn.insert(
          'transactions',
          txMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 2. Accounts
      final fromAccounts = await txn.query(
        'accounts',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      for (var acc in fromAccounts) {
        await txn.insert('accounts', {
          'username': toUsername,
          'name': acc['name'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // 3. Budgets
      final fromBudgets = await txn.query(
        'budgets',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      for (var b in fromBudgets) {
        await txn.insert(
          'budgets',
          {
            'username': toUsername,
            'category': b['category'],
            'amount_limit': b['amount_limit'],
          },
          conflictAlgorithm: mergeWithExisting
              ? ConflictAlgorithm.ignore
              : ConflictAlgorithm.replace,
        );
      }

      // 4. Goals
      final fromGoals = await txn.query(
        'goals',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      for (var g in fromGoals) {
        final goalMap = Map<String, dynamic>.from(g);
        goalMap['username'] = toUsername;
        await txn.insert(
          'goals',
          goalMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 5. Profile
      final fromProfile = await txn.query(
        'profiles',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      final toProfile = await txn.query(
        'profiles',
        where: 'username = ?',
        whereArgs: [toUsername],
      );
      if (fromProfile.isNotEmpty) {
        if (toProfile.isEmpty) {
          final pMap = Map<String, dynamic>.from(fromProfile.first);
          pMap['username'] = toUsername;
          await txn.insert(
            'profiles',
            pMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else if (!mergeWithExisting) {
          final f = fromProfile.first;
          await txn.update(
            'profiles',
            {
              'currency': f['currency'],
              'theme': f['theme'],
              'primary_color': f['primary_color'],
              'secondary_color': f['secondary_color'],
              'text_color': f['text_color'],
            },
            where: 'username = ?',
            whereArgs: [toUsername],
          );
        }
      }

      // 6. Loans
      final fromLoans = await txn.query(
        'loans',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      for (var l in fromLoans) {
        final lMap = Map<String, dynamic>.from(l);
        lMap['username'] = toUsername;
        await txn.insert(
          'loans',
          lMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 7. Planned Transactions
      final fromPlans = await txn.query(
        'planned_transactions',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      for (var p in fromPlans) {
        final pMap = Map<String, dynamic>.from(p);
        pMap['username'] = toUsername;
        await txn.insert(
          'planned_transactions',
          pMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 8. Delete migrated local user account and all redundant local records
      await txn.delete(
        'users',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      await txn.delete(
        'profiles',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      await txn.delete(
        'transactions',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      await txn.delete(
        'accounts',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      await txn.delete(
        'budgets',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      await txn.delete(
        'goals',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      await txn.delete(
        'loans',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
      await txn.delete(
        'planned_transactions',
        where: 'username = ?',
        whereArgs: [fromUsername],
      );
    });
  }

  /// Safely deletes a local user account and all its records (used when migrating to Google).
  Future<void> deleteLocalUser(String username) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('users', where: 'username = ?', whereArgs: [username]);
      await txn.delete(
        'profiles',
        where: 'username = ?',
        whereArgs: [username],
      );
      await txn.delete(
        'transactions',
        where: 'username = ?',
        whereArgs: [username],
      );
      await txn.delete(
        'accounts',
        where: 'username = ?',
        whereArgs: [username],
      );
      await txn.delete('budgets', where: 'username = ?', whereArgs: [username]);
      await txn.delete('goals', where: 'username = ?', whereArgs: [username]);
      await txn.delete('loans', where: 'username = ?', whereArgs: [username]);
      await txn.delete('planned_transactions', where: 'username = ?', whereArgs: [username]);
    });
  }

  /// Registers or signs in a Google user, binding their ledger records to their Google email.
  Future<bool> authenticateOrRegisterGoogleUser({
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final db = await database;
    final cleanEmail = email.trim();
    final results = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE OR email = ? COLLATE NOCASE',
      whereArgs: [cleanEmail, cleanEmail],
    );

    if (results.isEmpty) {
      final salt = SecurityHelper.generateSalt();
      final hash = SecurityHelper.hashPassword(
        'GOOGLE_OAUTH_PROTECTED_${SecurityHelper.generateSalt()}',
        salt,
      );

      await db.insert('users', {
        'username': cleanEmail,
        'email': cleanEmail.toLowerCase(),
        'password_hash': hash,
        'salt': salt,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('profiles', {
        'username': cleanEmail,
        'display_name': displayName.isNotEmpty
            ? displayName
            : cleanEmail.split('@').first,
        'bio': 'Google Account • Cloud Synced',
        'photo_path': photoUrl,
        'primary_color': const Color(0xFFE4572E).toARGB32(),
        'secondary_color': const Color(0xFFF6F0E1).toARGB32(),
        'text_color': null,
        'theme': 'Ledger',
        'currency': '\$',
        'created_at': DateTime.now().toIso8601String(),
      });

      for (var acc in ['Main', 'Cash', 'Credit Card', 'Digital Wallet']) {
        await db.insert('accounts', {
          'username': cleanEmail,
          'name': acc,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      final defaultBudgets = {
        'Food & Dining': 5000.0,
        'Housing & Rent': 1500.0,
        'Transportation': 3000.0,
        'Entertainment': 2000.0,
      };
      for (var b in defaultBudgets.entries) {
        await db.insert('budgets', {
          'username': cleanEmail,
          'category': b.key,
          'amount_limit': b.value,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } else {
      final user = results.first;
      final canonicalUsername = user['username'] as String;
      if (user['email'] == null || (user['email'] as String).isEmpty) {
        await db.update(
          'users',
          {'email': cleanEmail.toLowerCase()},
          where: 'username = ? COLLATE NOCASE',
          whereArgs: [canonicalUsername],
        );
      }

      if (displayName.isNotEmpty || photoUrl != null) {
        final currentProfile = await loadProfile(canonicalUsername);
        final hasCustomUploadedPhoto =
            currentProfile.photoPath != null &&
            currentProfile.photoPath!.isNotEmpty &&
            !currentProfile.photoPath!.startsWith('http');
        await saveProfile(
          currentProfile.copyWith(
            displayName: displayName.isNotEmpty
                ? displayName
                : currentProfile.displayName,
            photoPath: hasCustomUploadedPhoto
                ? currentProfile.photoPath
                : (photoUrl ?? currentProfile.photoPath),
          ),
        );
      }
    }

    return true;
  }

  Future<bool> changePassword(
    String username,
    String currentPassword,
    String newPassword,
  ) async {
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

    // Default profile for new account: always clean Ledger base theme
    const defPrimary = Color(0xFFE4572E);
    const defSecondary = Color(0xFFF6F0E1);
    const defTheme = 'Ledger';

    final profile = UserProfile(
      username: username,
      displayName: username,
      primaryColor: defPrimary,
      secondaryColor: defSecondary,
      textColor: null,
      theme: defTheme,
    );
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

  /// Fast O(1) single transaction insert or update
  Future<void> insertTransaction(
    String username,
    model.Transaction tx,
  ) async {
    final db = await database;
    await db.insert(
      'transactions',
      {
        'id': tx.id,
        'username': username,
        'title': tx.title,
        'amount': tx.amount,
        'date': tx.date.toIso8601String(),
        'is_income': tx.isIncome ? 1 : 0,
        'category': tx.category,
        'account': tx.account,
        'recurrence': tx.recurrence,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fast O(1) single transaction deletion by ID
  Future<void> deleteSingleTransaction(String id, {String? username}) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: username == null ? 'id = ?' : 'id = ? AND username = ?',
      whereArgs: [id, ?username],
    );
  }

  /// High-performance batch transaction saver for bulk migrations and cloud sync restores
  Future<void> saveTransactions(
    String username,
    List<model.Transaction> txs,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'transactions',
        where: 'username = ?',
        whereArgs: [username],
      );
      final old = {for (final row in existing) row['id']: row};
      final ids = txs.map((t) => t.id).toSet();
      for (final row in existing) {
        if (!ids.contains(row['id'])) {
          await txn.delete(
            'transactions',
            where: 'username = ? AND id = ?',
            whereArgs: [username, row['id']],
          );
        }
      }
      for (final tx in txs) {
        final row = SqliteLedgerStore.transactionRow(username, tx);
        final previous = old[tx.id];
        if (previous != null &&
            row.entries.every((e) => previous[e.key] == e.value)) {
          continue;
        }
        await txn.insert(
          'transactions',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
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
    return map.isNotEmpty
        ? map
        : {
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
  Future<List<SavingsGoal>> loadGoals(
    String username, {
    bool includeArchived = false,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final where = includeArchived
          ? 'username = ?'
          : 'username = ? AND (is_archived = 0 OR is_archived IS NULL)';
      final results = await txn.query(
        'goals',
        where: where,
        whereArgs: [username],
      );

      // Two scoped reads instead of one entry query for every goal.
      final allEntries = await txn.rawQuery(
        '''
      SELECT e.* FROM goal_entries e JOIN goals g
        ON g.id = e.goal_id AND g.username = e.username
      WHERE g.username = ? ${includeArchived ? '' : 'AND (g.is_archived = 0 OR g.is_archived IS NULL)'}
      ORDER BY e.date DESC
    ''',
        [username],
      );
      final grouped = <String, List<Map<String, Object?>>>{};
      for (final entry in allEntries) {
        grouped.putIfAbsent(entry['goal_id'] as String, () => []).add(entry);
      }
      final goals = <SavingsGoal>[];
      for (final r in results) {
        final goalId = r['id'] as String;
        final entryRows = grouped[goalId] ?? const [];
        final entries = entryRows
            .map(
              (e) => GoalEntry(
                id: e['id'] as String,
                goalId: e['goal_id'] as String,
                amount: (e['amount'] as num).toDouble(),
                date: DateTime.parse(e['date'] as String),
                note: e['note'] as String?,
                createdAt: e['created_at'] != null
                    ? DateTime.parse(e['created_at'] as String)
                    : DateTime.now(),
              ),
            )
            .toList();

        goals.add(
          SavingsGoal(
            id: goalId,
            title: r['title'] as String,
            target: (r['target_amount'] as num).toDouble(),
            saved: (r['current_amount'] as num).toDouble(),
            color: Color(r['color'] as int),
            icon: resolveGoalIconByCodePoint(r['icon'] as int?),
            dueDate: r['due_date'] != null
                ? DateTime.tryParse(r['due_date'] as String)
                : null,
            periodType: (r['period_type'] as String?) ?? 'monthly',
            isRecurring: (r['is_recurring'] as int?) == 1,
            recurrence: (r['recurrence'] as String?) ?? 'none',
            isCompleted: (r['is_completed'] as int?) == 1,
            isFailed: (r['is_failed'] as int?) == 1,
            isArchived: (r['is_archived'] as int?) == 1,
            createdAt: r['created_at'] != null
                ? DateTime.tryParse(r['created_at'] as String) ?? DateTime.now()
                : DateTime.now(),
            entries: entries,
          ),
        );
      }
      return goals;
    });
  }

  Future<void> saveGoals(String username, List<SavingsGoal> goals) async {
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'goals',
        where: 'username = ?',
        whereArgs: [username],
      );
      final old = {for (final row in existing) row['id']: row};
      final ids = goals.map((g) => g.id).toSet();
      for (final row in existing) {
        if (row['is_archived'] != 1 && !ids.contains(row['id'])) {
          await txn.delete(
            'goals',
            where: 'username = ? AND id = ?',
            whereArgs: [username, row['id']],
          );
        }
      }
      for (final goal in goals) {
        final row = SqliteLedgerStore.goalRow(username, goal);
        final previous = old[goal.id];
        if (previous != null &&
            row.entries.every((e) => previous[e.key] == e.value)) {
          continue;
        }
        await txn.insert(
          'goals',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Inserts or replaces a single goal (upsert).
  Future<void> upsertGoal(String username, SavingsGoal goal) async {
    final db = await database;
    await db.insert('goals', {
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Soft-delete a goal: archive if completed or >10% progress, else hard-delete.
  Future<void> softDeleteGoal(String username, String goalId) async {
    final db = await database;
    final results = await db.query('goals', where: 'id = ? AND username = ?', whereArgs: [goalId, username]);
    if (results.isEmpty) return;
    final r = results.first;
    final saved = (r['current_amount'] as num).toDouble();
    final target = (r['target_amount'] as num).toDouble();
    final isCompleted = (r['is_completed'] as int?) == 1;
    final progress = target > 0 ? saved / target : 0.0;

    if (isCompleted || progress >= 0.10) {
      await db.update('goals', {'is_archived': 1}, where: 'id = ? AND username = ?', whereArgs: [goalId, username]);
    } else {
      await db.delete('goals', where: 'id = ? AND username = ?', whereArgs: [goalId, username]);
      await db.delete('goal_entries', where: 'goal_id = ? AND username = ?', whereArgs: [goalId, username]);
    }
  }

  /// Explicit removal, including archived goals. Triggers persist the cloud
  /// tombstone in this same transaction. Financial transactions are retained.
  Future<void> permanentlyDeleteGoal(String username, String goalId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('goal_entries', where: 'username = ? AND goal_id = ?', whereArgs: [username, goalId]);
      await txn.delete('goals', where: 'username = ? AND id = ?', whereArgs: [username, goalId]);
    });
  }

  /// Update goal status flags (completed, failed, archived).
  Future<void> updateGoalStatus(String username, String goalId, {bool? isCompleted, bool? isFailed, bool? isArchived}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (isCompleted != null) updates['is_completed'] = isCompleted ? 1 : 0;
    if (isFailed != null) updates['is_failed'] = isFailed ? 1 : 0;
    if (isArchived != null) updates['is_archived'] = isArchived ? 1 : 0;
    if (updates.isNotEmpty) {
      await db.update('goals', updates, where: 'id = ? AND username = ?', whereArgs: [goalId, username]);
    }
  }

  // --- GOAL ENTRIES ---
  Future<List<GoalEntry>> loadGoalEntries(String username, String goalId) async {
    final db = await database;
    final results = await db.query(
      'goal_entries',
      where: 'goal_id = ? AND username = ?',
      whereArgs: [goalId, username],
      orderBy: 'date DESC',
    );
    return results.map((e) => GoalEntry(
          id: e['id'] as String,
          goalId: e['goal_id'] as String,
          amount: (e['amount'] as num).toDouble(),
          date: DateTime.parse(e['date'] as String),
          note: e['note'] as String?,
          createdAt: e['created_at'] != null
              ? DateTime.parse(e['created_at'] as String)
              : DateTime.now(),
        )).toList();
  }

  /// Adds a contribution entry and atomically recalculates the goal's saved total.
  Future<void> addGoalEntry(String username, GoalEntry entry) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('goal_entries', {
        'id': entry.id,
        'goal_id': entry.goalId,
        'username': username,
        'amount': entry.amount,
        'date': entry.date.toIso8601String(),
        'note': entry.note,
        'created_at': entry.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Recalculate goal total from all entries
      final sumResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM goal_entries WHERE goal_id = ? AND username = ?',
        [entry.goalId, username],
      );
      final total = (sumResult.first['total'] as num).toDouble();
      await txn.update('goals', {'current_amount': total},
          where: 'id = ? AND username = ?', whereArgs: [entry.goalId, username]);
    });
  }

  /// Updates an existing contribution entry and recalculates the goal's saved total.
  Future<void> updateGoalEntry(String username, GoalEntry entry) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('goal_entries', {
        'amount': entry.amount,
        'date': entry.date.toIso8601String(),
        'note': entry.note,
      }, where: 'id = ? AND username = ?', whereArgs: [entry.id, username]);

      final sumResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM goal_entries WHERE goal_id = ? AND username = ?',
        [entry.goalId, username],
      );
      final total = (sumResult.first['total'] as num).toDouble();
      await txn.update('goals', {'current_amount': total},
          where: 'id = ? AND username = ?', whereArgs: [entry.goalId, username]);
    });
  }

  /// Deletes a contribution entry and recalculates the goal's saved total.
  Future<void> deleteGoalEntry(String username, String entryId, String goalId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('goal_entries', where: 'id = ? AND username = ?', whereArgs: [entryId, username]);

      final sumResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM goal_entries WHERE goal_id = ? AND username = ?',
        [goalId, username],
      );
      final total = (sumResult.first['total'] as num).toDouble();
      await txn.update('goals', {'current_amount': total},
          where: 'id = ? AND username = ?', whereArgs: [goalId, username]);
    });
  }

  /// Deletes a goal entry linked to a transaction if present.
  Future<void> deleteGoalEntryByTransactionId(String username, String txId) async {
    final db = await database;
    final entries = await db.query(
      'goal_entries',
      where: 'id = ? AND username = ?',
      whereArgs: ['tx_$txId', username],
    );
    if (entries.isNotEmpty) {
      final goalId = entries.first['goal_id'] as String;
      await deleteGoalEntry(username, 'tx_$txId', goalId);
    }
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
    return list.isNotEmpty
        ? list
        : ['Main', 'Cash', 'Credit Card', 'Digital Wallet'];
  }

  Future<void> saveAccounts(String username, List<String> accounts) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'accounts',
        where: 'username = ?',
        whereArgs: [username],
      );
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

    buffer.writeln(
      '-- ========================================================',
    );
    buffer.writeln('-- Balance Tracker SQL Ledger Backup');
    buffer.writeln('-- User: $username');
    buffer.writeln('-- Export Date: $now');
    buffer.writeln(
      '-- ========================================================\n',
    );

    buffer.writeln('BEGIN TRANSACTION;\n');

    // Profile
    final profiles = await db.query(
      'profiles',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (profiles.isNotEmpty) {
      final p = profiles.first;
      buffer.writeln('-- User Profile');
      buffer.writeln(
        "INSERT INTO profiles (username, display_name, bio, photo_path, primary_color, secondary_color, currency, created_at) "
        "VALUES ('${p['username']}', '${p['display_name']}', '${p['bio']}', '${p['photo_path']}', ${p['primary_color']}, ${p['secondary_color']}, '${p['currency']}', '${p['created_at']}');\n",
      );
    }

    // Accounts
    final accounts = await db.query(
      'accounts',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (accounts.isNotEmpty) {
      buffer.writeln('-- Accounts & Wallets');
      for (var a in accounts) {
        buffer.writeln(
          "INSERT INTO accounts (username, name) VALUES ('$username', '${a['name']}');",
        );
      }
      buffer.writeln();
    }

    // Budgets
    final budgets = await db.query(
      'budgets',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (budgets.isNotEmpty) {
      buffer.writeln('-- Monthly Budgets');
      for (var b in budgets) {
        buffer.writeln(
          "INSERT INTO budgets (username, category, amount_limit) VALUES ('$username', '${b['category']}', ${b['amount_limit']});",
        );
      }
      buffer.writeln();
    }

    // Goals
    final goals = await db.query(
      'goals',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (goals.isNotEmpty) {
      buffer.writeln('-- Savings Goals');
      for (var g in goals) {
        buffer.writeln(
          "INSERT INTO goals (id, username, title, target_amount, current_amount, color, icon) VALUES ('${g['id']}', '$username', '${g['title']}', ${g['target_amount']}, ${g['current_amount']}, ${g['color']}, ${g['icon']});",
        );
      }
      buffer.writeln();
    }

    // Transactions
    final txs = await db.query(
      'transactions',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'date ASC',
    );
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

  // ---------------------------------------------------------------------------
  // Loans & Debts (Receivables & Payables)
  // ---------------------------------------------------------------------------
  Future<List<Loan>> loadLoans(String username) async {
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => Loan.fromJson(m)).toList();
  }

  Future<void> saveLoan(String username, Loan loan) async {
    final db = await database;
    await db.insert(
      'loans',
      {
        'id': loan.id,
        'username': username,
        'title': loan.title,
        'person_name': loan.personName,
        'amount': loan.amount,
        'due_date': loan.dueDate.toIso8601String(),
        'type': loan.type,
        'is_settled': loan.isSettled ? 1 : 0,
        'notes': loan.notes,
        'account': loan.account,
        'created_at': loan.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteLoan(String username, String loanId) async {
    final db = await database;
    await db.delete(
      'loans',
      where: 'username = ? AND id = ?',
      whereArgs: [username, loanId],
    );
  }

  Future<void> setLoanSettled(String username, String loanId, bool isSettled) async {
    final db = await database;
    await db.update(
      'loans',
      {'is_settled': isSettled ? 1 : 0},
      where: 'username = ? AND id = ?',
      whereArgs: [username, loanId],
    );
  }

  // ---------------------------------------------------------------------------
  // Planned / Future Transactions & Recurring Execution
  // ---------------------------------------------------------------------------
  Future<List<PlannedTransaction>> loadPlannedTransactions(String username) async {
    final db = await database;
    final maps = await db.query(
      'planned_transactions',
      where: 'username = ? AND is_processed = 0',
      whereArgs: [username],
      orderBy: 'date ASC',
    );
    return maps.map((m) => PlannedTransaction.fromJson(m)).toList();
  }

  Future<void> savePlannedTransaction(
    String username,
    PlannedTransaction plan,
  ) async {
    final db = await database;
    await db.insert(
      'planned_transactions',
      AtomicPlans.row(username, plan),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePlannedTransaction(String username, String planId) async {
    final db = await database;
    await db.delete(
      'planned_transactions',
      where: 'username = ? AND id = ?',
      whereArgs: [username, planId],
    );
  }

  Future<void> markPlannedTransactionProcessed(String username, String planId) async {
    final db = await database;
    await db.update(
      'planned_transactions',
      {'is_processed': 1},
      where: 'username = ? AND id = ?',
      whereArgs: [username, planId],
    );
  }
}
