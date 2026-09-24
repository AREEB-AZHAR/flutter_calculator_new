import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import 'database/app_database.dart';

class AppState {
  static String? currentUser;

  static const String _prefThemeKey = 'tally_active_theme';
  static const String _prefPrimaryColorKey = 'tally_primary_color';
  static const String _prefSecondaryColorKey = 'tally_secondary_color';
  static const String _prefTextColorKey = 'tally_text_color';
  static const String _prefCurrencyKey = 'tally_currency_symbol';

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
  static final ValueNotifier<Color?> customTextColorNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> profilePhotoNotifier = ValueNotifier(null);
  static final ValueNotifier<String> displayNameNotifier = ValueNotifier('');
  static final ValueNotifier<String> bioNotifier = ValueNotifier('');
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier(0);

  /// Initializes the saved global theme and colors from SharedPreferences before the app renders.
  static Future<void> initGlobalTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_prefThemeKey);
      if (savedTheme != null && themePresets.any((p) => p.name == savedTheme)) {
        themeNameNotifier.value = savedTheme;
        final preset = themePresets.firstWhere((p) => p.name == savedTheme);
        customPrimaryColorNotifier.value = preset.primary;
        customSecondaryColorNotifier.value = preset.secondary;
        avatarColorNotifier.value = preset.primary;
      }

      final pCol = prefs.getInt(_prefPrimaryColorKey);
      if (pCol != null) {
        customPrimaryColorNotifier.value = Color(pCol);
        avatarColorNotifier.value = Color(pCol);
      }
      final sCol = prefs.getInt(_prefSecondaryColorKey);
      if (sCol != null) {
        customSecondaryColorNotifier.value = Color(sCol);
      }
      final tCol = prefs.getInt(_prefTextColorKey);
      if (tCol != null) {
        customTextColorNotifier.value = Color(tCol);
      } else {
        customTextColorNotifier.value = null;
      }

      final savedCurrency = prefs.getString(_prefCurrencyKey);
      if (savedCurrency != null && savedCurrency.isNotEmpty) {
        currencyNotifier.value = savedCurrency;
      }
    } catch (e) {
      debugPrint('Error loading saved global theme: $e');
    }
  }

  /// Quickly switches to a brand preset (Ledger, Paper, Ink) and saves globally to SharedPreferences
  /// without abruptly closing or restarting the app.
  static Future<void> persistThemePreset(AppThemePreset preset) async {
    themeNameNotifier.value = preset.name;
    customPrimaryColorNotifier.value = preset.primary;
    customSecondaryColorNotifier.value = preset.secondary;
    customTextColorNotifier.value = null;
    avatarColorNotifier.value = preset.primary;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, preset.name);
      await prefs.setInt(_prefPrimaryColorKey, preset.primary.toARGB32());
      await prefs.setInt(_prefSecondaryColorKey, preset.secondary.toARGB32());
      await prefs.remove(_prefTextColorKey);
    } catch (e) {
      debugPrint('Error persisting preset theme: $e');
    }
  }

  // Initialize and load all data for user from SQLite database
  static Future<void> loadAllUserData(String username) async {
    currentUser = username;
    final db = AppDatabase.instance;

    final profile = await db.loadProfile(username);
    displayNameNotifier.value = profile.displayName;
    bioNotifier.value = profile.bio;
    profilePhotoNotifier.value = profile.photoPath;

    // If profile has a saved theme, restore it!
    if (profile.theme != null && profile.theme!.isNotEmpty) {
      themeNameNotifier.value = profile.theme!;
    }

    Color pCol = profile.primaryColor;
    Color sCol = profile.secondaryColor;
    Color? tCol = profile.textColor ?? customTextColorNotifier.value;

    // Heal legacy default if primaryColor matches old background (0xFF17493B) or old default (0xFF8B5CF6)
    if (pCol.toARGB32() == 0xFF17493B || pCol.toARGB32() == 0xFF8B5CF6) {
      if (customPrimaryColorNotifier.value.toARGB32() != 0xFF17493B &&
          customPrimaryColorNotifier.value.toARGB32() != 0xFF8B5CF6) {
        pCol = customPrimaryColorNotifier.value;
        sCol = customSecondaryColorNotifier.value;
      } else {
        final preset = themePresets.firstWhere((p) => p.name == themeNameNotifier.value, orElse: () => themePresets.first);
        pCol = preset.primary;
        sCol = preset.secondary;
      }
    }

    customPrimaryColorNotifier.value = pCol;
    customSecondaryColorNotifier.value = sCol;
    customTextColorNotifier.value = tCol;
    avatarColorNotifier.value = pCol;
    currencyNotifier.value = profile.currency;

    // Persist healed/synced profile to database
    await db.saveProfile(profile.copyWith(
      primaryColor: pCol,
      secondaryColor: sCol,
      textColor: tCol,
      theme: themeNameNotifier.value,
    ));

    transactionsNotifier.value = await db.loadTransactions(username);
    budgetsNotifier.value = await db.loadBudgets(username);
    goalsNotifier.value = await db.loadGoals(username);
    accountsNotifier.value = await db.loadAccounts(username);

    // Sync user's saved palette to SharedPreferences so next startup boots with this palette
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, themeNameNotifier.value);
      await prefs.setInt(_prefPrimaryColorKey, pCol.toARGB32());
      await prefs.setInt(_prefSecondaryColorKey, sCol.toARGB32());
      if (profile.textColor != null) {
        await prefs.setInt(_prefTextColorKey, profile.textColor!.toARGB32());
      } else {
        await prefs.remove(_prefTextColorKey);
      }
      await prefs.setString(_prefCurrencyKey, profile.currency);
    } catch (_) {}
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final updatedProfile = profile.copyWith(theme: themeNameNotifier.value);
    await AppDatabase.instance.saveProfile(updatedProfile);
    displayNameNotifier.value = updatedProfile.displayName;
    bioNotifier.value = updatedProfile.bio;
    profilePhotoNotifier.value = updatedProfile.photoPath;
    customPrimaryColorNotifier.value = updatedProfile.primaryColor;
    customSecondaryColorNotifier.value = updatedProfile.secondaryColor;
    customTextColorNotifier.value = updatedProfile.textColor;
    avatarColorNotifier.value = updatedProfile.primaryColor;
    currencyNotifier.value = updatedProfile.currency;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, themeNameNotifier.value);
      await prefs.setInt(_prefPrimaryColorKey, updatedProfile.primaryColor.toARGB32());
      await prefs.setInt(_prefSecondaryColorKey, updatedProfile.secondaryColor.toARGB32());
      if (updatedProfile.textColor != null) {
        await prefs.setInt(_prefTextColorKey, updatedProfile.textColor!.toARGB32());
      } else {
        await prefs.remove(_prefTextColorKey);
      }
      await prefs.setString(_prefCurrencyKey, updatedProfile.currency);
    } catch (e) {
      debugPrint('Error saving colors to SharedPreferences: $e');
    }
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

  /// Safely deletes a transaction, persists the removal to SQLite, and displays a SnackBar with an 'Undo' option.
  /// If the user taps 'Undo', the transaction is restored at its chronological position and saved to SQLite.
  static void deleteTransactionWithUndo(BuildContext context, Transaction tx) {
    final currentList = List<Transaction>.from(transactionsNotifier.value);
    final originalIndex = currentList.indexWhere((t) => t.id == tx.id);
    currentList.removeWhere((t) => t.id == tx.id);
    transactionsNotifier.value = currentList;
    if (currentUser != null) {
      saveTransactions(currentUser!, currentList);
    }

    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${tx.title}" deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.amberAccent,
            onPressed: () {
              final restoredList = List<Transaction>.from(transactionsNotifier.value);
              if (!restoredList.any((t) => t.id == tx.id)) {
                if (originalIndex >= 0 && originalIndex <= restoredList.length) {
                  restoredList.insert(originalIndex, tx);
                } else {
                  restoredList.add(tx);
                }
                restoredList.sort((a, b) => b.date.compareTo(a.date));
                transactionsNotifier.value = restoredList;
                if (currentUser != null) {
                  saveTransactions(currentUser!, restoredList);
                }
              }
            },
          ),
        ),
      );
    } catch (_) {}
  }

  /// Safely deletes a savings goal, persists the removal to SQLite, and displays a SnackBar with an 'Undo' option.
  /// If the user taps 'Undo', the goal is restored at its original position and saved to SQLite.
  static void deleteGoalWithUndo(BuildContext context, SavingsGoal goal) {
    final currentGoals = List<SavingsGoal>.from(goalsNotifier.value);
    final originalIndex = currentGoals.indexWhere((g) => g.id == goal.id);
    currentGoals.removeWhere((g) => g.id == goal.id);
    goalsNotifier.value = currentGoals;
    if (currentUser != null) {
      saveGoals(currentUser!, currentGoals);
    }

    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Goal "${goal.title}" deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.amberAccent,
            onPressed: () {
              final restoredGoals = List<SavingsGoal>.from(goalsNotifier.value);
              if (!restoredGoals.any((g) => g.id == goal.id)) {
                if (originalIndex >= 0 && originalIndex <= restoredGoals.length) {
                  restoredGoals.insert(originalIndex, goal);
                } else {
                  restoredGoals.add(goal);
                }
                goalsNotifier.value = restoredGoals;
                if (currentUser != null) {
                  saveGoals(currentUser!, restoredGoals);
                }
              }
            },
          ),
        ),
      );
    } catch (_) {}
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

  static Future<void> saveTheme(String? username, String themeName) async {
    themeNameNotifier.value = themeName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, themeName);
    } catch (e) {
      debugPrint('Error saving theme to SharedPreferences: $e');
    }
    if (username != null) {
      try {
        final p = await AppDatabase.instance.loadProfile(username);
        await AppDatabase.instance.saveProfile(p.copyWith(theme: themeName));
      } catch (_) {}
    }
  }

  static Future<String> loadTheme(String? username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefThemeKey);
      if (saved != null) {
        themeNameNotifier.value = saved;
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading theme from SharedPreferences: $e');
    }
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

  static Future<void> setCurrency(String currency) async {
    currencyNotifier.value = currency;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCurrencyKey, currency);
    } catch (_) {}
    if (currentUser != null) {
      final p = await AppDatabase.instance.loadProfile(currentUser!);
      await AppDatabase.instance.saveProfile(p.copyWith(currency: currency));
    }
  }

  static Future<void> saveCurrency(String username, String currency) async {
    await setCurrency(currency);
  }

  static Future<String> loadCurrency(String username) async {
    final p = await AppDatabase.instance.loadProfile(username);
    return p.currency;
  }
}
