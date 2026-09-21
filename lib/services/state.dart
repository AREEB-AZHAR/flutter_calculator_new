import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/user_profile.dart';
import 'database/app_database.dart';

class AppState {
  static String? currentUser;

  static final ValueNotifier<String> currencyNotifier = ValueNotifier('\$');
  static final ValueNotifier<List<Transaction>> transactionsNotifier = ValueNotifier([]);
  static final ValueNotifier<Map<String, double>> budgetsNotifier = ValueNotifier({
    'Food & Dining': 500.0,
    'Housing & Rent': 1500.0,
    'Transportation': 300.0,
    'Entertainment': 200.0,
  });
  static final ValueNotifier<List<String>> accountsNotifier = ValueNotifier(['Main', 'Cash', 'Credit Card', 'Digital Wallet']);
  static final ValueNotifier<Color> avatarColorNotifier = ValueNotifier(const Color(0xFFE4572E));
  static final ValueNotifier<String> themeNameNotifier = ValueNotifier('Ledger');
  static final ValueNotifier<List<SavingsGoal>> goalsNotifier = ValueNotifier([]);

  // Graphic Theme & Profile Customization Notifiers
  static final ValueNotifier<Color> customPrimaryColorNotifier = ValueNotifier(const Color(0xFFE4572E));
  static final ValueNotifier<Color> customSecondaryColorNotifier = ValueNotifier(const Color(0xFFF6F0E1));
  static final ValueNotifier<String?> profilePhotoNotifier = ValueNotifier(null);
  static final ValueNotifier<String> displayNameNotifier = ValueNotifier('');
  static final ValueNotifier<String> bioNotifier = ValueNotifier('');
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier(0);

  // Initialize and load all data for user from SQLite database
  static Future<void> loadAllUserData(String username) async {
    currentUser = username;
    final db = AppDatabase.instance;

    final profile = await db.loadProfile(username);
    displayNameNotifier.value = profile.displayName;
    bioNotifier.value = profile.bio;
    profilePhotoNotifier.value = profile.photoPath;

    // Heal legacy default if primaryColor matches background (e.g. 0xFF17493B) or old default (0xFF8B5CF6)
    Color pCol = profile.primaryColor;
    Color sCol = profile.secondaryColor;
    if (pCol.toARGB32() == 0xFF17493B || pCol.toARGB32() == 0xFF8B5CF6) {
      pCol = const Color(0xFFE4572E);
      sCol = const Color(0xFFF6F0E1);
    }
    customPrimaryColorNotifier.value = pCol;
    customSecondaryColorNotifier.value = sCol;
    avatarColorNotifier.value = pCol;
    currencyNotifier.value = profile.currency;

    transactionsNotifier.value = await db.loadTransactions(username);
    budgetsNotifier.value = await db.loadBudgets(username);
    goalsNotifier.value = await db.loadGoals(username);
    accountsNotifier.value = await db.loadAccounts(username);
  }

  static Future<void> saveProfile(UserProfile profile) async {
    await AppDatabase.instance.saveProfile(profile);
    displayNameNotifier.value = profile.displayName;
    bioNotifier.value = profile.bio;
    profilePhotoNotifier.value = profile.photoPath;
    customPrimaryColorNotifier.value = profile.primaryColor;
    customSecondaryColorNotifier.value = profile.secondaryColor;
    avatarColorNotifier.value = profile.primaryColor;
    currencyNotifier.value = profile.currency;
  }

  static Future<void> saveGoals(String username, List<SavingsGoal> goals) async {
    await AppDatabase.instance.saveGoals(username, goals);
    goalsNotifier.value = List.from(goals);
  }

  static Future<List<SavingsGoal>> loadGoals(String username) async {
    return await AppDatabase.instance.loadGoals(username);
  }

  static Future<void> saveTransactions(String username, List<Transaction> txs) async {
    await AppDatabase.instance.saveTransactions(username, txs);
    transactionsNotifier.value = List.from(txs);
  }

  static Future<List<Transaction>> loadTransactions(String username) async {
    return await AppDatabase.instance.loadTransactions(username);
  }

  static Future<void> saveBudgets(String username, Map<String, double> budgets) async {
    await AppDatabase.instance.saveBudgets(username, budgets);
    budgetsNotifier.value = Map.from(budgets);
  }

  static Future<Map<String, double>> loadBudgets(String username) async {
    return await AppDatabase.instance.loadBudgets(username);
  }

  static Future<void> saveAccounts(String username, List<String> accounts) async {
    await AppDatabase.instance.saveAccounts(username, accounts);
    accountsNotifier.value = List.from(accounts);
  }

  static Future<List<String>> loadAccounts(String username) async {
    return await AppDatabase.instance.loadAccounts(username);
  }

  static Future<void> saveTheme(String username, String themeName) async {
    themeNameNotifier.value = themeName;
  }

  static Future<String> loadTheme(String username) async {
    return themeNameNotifier.value;
  }

  static Future<void> saveAvatarColor(String username, Color color) async {
    avatarColorNotifier.value = color;
    customPrimaryColorNotifier.value = color;
    if (currentUser != null) {
      final p = await AppDatabase.instance.loadProfile(username);
      await AppDatabase.instance.saveProfile(p.copyWith(primaryColor: color));
    }
  }

  static Future<Color> loadAvatarColor(String username) async {
    return avatarColorNotifier.value;
  }

  static Future<void> saveCurrency(String username, String currency) async {
    currencyNotifier.value = currency;
    if (currentUser != null) {
      final p = await AppDatabase.instance.loadProfile(username);
      await AppDatabase.instance.saveProfile(p.copyWith(currency: currency));
    }
  }

  static Future<String> loadCurrency(String username) async {
    final p = await AppDatabase.instance.loadProfile(username);
    return p.currency;
  }
}
