import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/user_profile.dart';
import '../models/loan.dart';
import '../models/planned_transaction.dart';
import '../utils/constants.dart';
import 'database/app_database.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';
import 'monetization_service.dart';

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
  static final ValueNotifier<List<Loan>> loansNotifier = ValueNotifier([]);
  static final ValueNotifier<List<PlannedTransaction>> plannedTransactionsNotifier = ValueNotifier([]);

  // Graphic Theme & Profile Customization Notifiers
  static final ValueNotifier<Color> customPrimaryColorNotifier = ValueNotifier(const Color(0xFFE4572E));
  static final ValueNotifier<Color> customSecondaryColorNotifier = ValueNotifier(const Color(0xFFF6F0E1));
  static final ValueNotifier<Color?> customTextColorNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> profilePhotoNotifier = ValueNotifier(null);
  static final ValueNotifier<String> displayNameNotifier = ValueNotifier('');
  static final ValueNotifier<String> bioNotifier = ValueNotifier('');
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier(0);
  static Timer? _undoSnackBarTimer;

  /// Initializes the saved global theme and colors from SharedPreferences before the app renders.
  static Future<void> initGlobalTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var savedTheme = prefs.getString(_prefThemeKey);
      const freeThemes = ['Ledger', 'Paper', 'Ink'];
      if (!MonetizationService.isPro && (savedTheme == null || !freeThemes.contains(savedTheme))) {
        savedTheme = 'Ledger';
      }

      if (themePresets.any((p) => p.name == savedTheme)) {
        themeNameNotifier.value = savedTheme!;
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

  /// Resets theme and color notifiers back to default Ledger base palette.
  static void resetThemeToDefault() {
    final ledger = themePresets.firstWhere((p) => p.name == 'Ledger');
    themeNameNotifier.value = ledger.name;
    customPrimaryColorNotifier.value = ledger.primary;
    customSecondaryColorNotifier.value = ledger.secondary;
    customTextColorNotifier.value = null;
    avatarColorNotifier.value = ledger.primary;
  }

  /// Completely wipes all session data from memory and resets theme and monetization entitlements.
  static Future<void> clearUserSession() async {
    currentUser = null;
    transactionsNotifier.value = [];
    budgetsNotifier.value = {
      'Food & Dining': 500.0,
      'Housing & Rent': 1500.0,
      'Transportation': 300.0,
      'Entertainment': 200.0,
    };
    accountsNotifier.value = ['Main', 'Cash', 'Credit Card', 'Digital Wallet'];
    goalsNotifier.value = [];
    loansNotifier.value = [];
    plannedTransactionsNotifier.value = [];
    displayNameNotifier.value = '';
    bioNotifier.value = '';
    profilePhotoNotifier.value = null;
    activeTabNotifier.value = 0;
    _undoSnackBarTimer?.cancel();
    _undoSnackBarTimer = null;
    resetThemeToDefault();
    MonetizationService.resetToLoggedOut();
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
      if (currentUser != null && currentUser!.isNotEmpty) {
        await prefs.setString('${_prefThemeKey}_$currentUser', preset.name);
        await prefs.setInt('${_prefPrimaryColorKey}_$currentUser', preset.primary.toARGB32());
        await prefs.setInt('${_prefSecondaryColorKey}_$currentUser', preset.secondary.toARGB32());
        await prefs.remove('${_prefTextColorKey}_$currentUser');
      }
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

    // 1. Load monetization entitlements strictly scoped to this user
    await MonetizationService.loadUserEntitlements(username);

    // 2. Load user profile from SQLite database
    final profile = await db.loadProfile(username);
    displayNameNotifier.value = profile.displayName;
    bioNotifier.value = profile.bio;
    profilePhotoNotifier.value = profile.photoPath;

    // 3. Strict Theme Sanitization: Free themes are strictly Ledger, Paper, and Ink
    const freeThemes = ['Ledger', 'Paper', 'Ink'];
    String effectiveTheme = profile.theme ?? 'Ledger';
    if (!themePresets.any((p) => p.name == effectiveTheme)) {
      effectiveTheme = 'Ledger';
    }

    final isPremium = !freeThemes.contains(effectiveTheme);

    Color pCol = profile.primaryColor;
    Color sCol = profile.secondaryColor;
    Color? tCol = profile.textColor;

    // If user is not Pro, revert any premium theme or custom studio modifications
    if (!MonetizationService.isPro) {
      if (isPremium) {
        effectiveTheme = 'Ledger';
      }
      final preset = themePresets.firstWhere((p) => p.name == effectiveTheme, orElse: () => themePresets.first);
      pCol = preset.primary;
      sCol = preset.secondary;
      tCol = null;
    } else {
      // Pro user: heal legacy default if primaryColor matches old background or old default
      if (pCol.toARGB32() == 0xFF17493B || pCol.toARGB32() == 0xFF8B5CF6) {
        final preset = themePresets.firstWhere((p) => p.name == effectiveTheme, orElse: () => themePresets.first);
        pCol = preset.primary;
        sCol = preset.secondary;
      }
    }

    themeNameNotifier.value = effectiveTheme;
    customPrimaryColorNotifier.value = pCol;
    customSecondaryColorNotifier.value = sCol;
    customTextColorNotifier.value = tCol;
    avatarColorNotifier.value = pCol;
    currencyNotifier.value = profile.currency;

    // Persist healed/sanitized profile to database
    await db.saveProfile(profile.copyWith(
      primaryColor: pCol,
      secondaryColor: sCol,
      textColor: tCol,
      theme: effectiveTheme,
    ));

    transactionsNotifier.value = await db.loadTransactions(username);
    budgetsNotifier.value = await db.loadBudgets(username);
    goalsNotifier.value = await db.loadGoals(username);
    accountsNotifier.value = await db.loadAccounts(username);
    loansNotifier.value = await db.loadLoans(username);
    plannedTransactionsNotifier.value = await db.loadPlannedTransactions(username);
    await checkAndProcessPlannedAndRecurring(username);

    // Sync user's saved palette to SharedPreferences so next startup boots with this palette
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefThemeKey}_$username', effectiveTheme);
      await prefs.setInt('${_prefPrimaryColorKey}_$username', pCol.toARGB32());
      await prefs.setInt('${_prefSecondaryColorKey}_$username', sCol.toARGB32());
      if (tCol != null) {
        await prefs.setInt('${_prefTextColorKey}_$username', tCol.toARGB32());
      } else {
        await prefs.remove('${_prefTextColorKey}_$username');
      }

      await prefs.setString(_prefThemeKey, effectiveTheme);
      await prefs.setInt(_prefPrimaryColorKey, pCol.toARGB32());
      await prefs.setInt(_prefSecondaryColorKey, sCol.toARGB32());
      if (tCol != null) {
        await prefs.setInt(_prefTextColorKey, tCol.toARGB32());
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

    // Real-time Cloud Sync for Profile & Avatar
    CloudSyncService.syncProfileToCloud(updatedProfile);
  }

  static Future<void> saveGoals(String username, List<SavingsGoal> goals) async {
    await AppDatabase.instance.saveGoals(username, goals);
    goalsNotifier.value = List.from(goals);
    CloudSyncService.syncGoalsToCloud(goals);
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
  /// The undo banner automatically dismisses after exactly 5 seconds.
  static void deleteTransactionWithUndo(BuildContext context, Transaction tx) {
    final currentList = List<Transaction>.from(transactionsNotifier.value);
    final originalIndex = currentList.indexWhere((t) => t.id == tx.id);
    currentList.removeWhere((t) => t.id == tx.id);
    transactionsNotifier.value = currentList;
    if (currentUser != null) {
      saveTransactions(currentUser!, currentList);
    }
    // Delete from Firestore immediately
    CloudSyncService.deleteTransactionFromCloud(tx.id);

    try {
      final messenger = ScaffoldMessenger.of(context);
      _undoSnackBarTimer?.cancel();
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(
        SnackBar(
          content: Text('"${tx.title}" deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.amberAccent,
            onPressed: () {
              _undoSnackBarTimer?.cancel();
              _undoSnackBarTimer = null;
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
                // Re-sync restored transaction to cloud
                CloudSyncService.syncTransactionToCloud(tx);
              }
            },
          ),
        ),
      );
      _undoSnackBarTimer = Timer(const Duration(seconds: 5), () {
        try {
          controller.close();
        } catch (_) {}
      });
      controller.closed.then((_) {
        _undoSnackBarTimer?.cancel();
        _undoSnackBarTimer = null;
      });
    } catch (_) {}
  }

  /// Safely deletes a savings goal, persists the removal to SQLite, and displays a SnackBar with an 'Undo' option.
  /// If the user taps 'Undo', the goal is restored at its original position and saved to SQLite.
  /// The undo banner automatically dismisses after exactly 5 seconds.
  static void deleteGoalWithUndo(BuildContext context, SavingsGoal goal) {
    final currentGoals = List<SavingsGoal>.from(goalsNotifier.value);
    final originalIndex = currentGoals.indexWhere((g) => g.id == goal.id);
    currentGoals.removeWhere((g) => g.id == goal.id);
    goalsNotifier.value = currentGoals;
    if (currentUser != null) {
      saveGoals(currentUser!, currentGoals);
    }
    // Delete from Firestore immediately
    CloudSyncService.deleteGoalFromCloud(goal.id);

    try {
      final messenger = ScaffoldMessenger.of(context);
      _undoSnackBarTimer?.cancel();
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(
        SnackBar(
          content: Text('Goal "${goal.title}" deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.amberAccent,
            onPressed: () {
              _undoSnackBarTimer?.cancel();
              _undoSnackBarTimer = null;
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
      _undoSnackBarTimer = Timer(const Duration(seconds: 5), () {
        try {
          controller.close();
        } catch (_) {}
      });
      controller.closed.then((_) {
        _undoSnackBarTimer?.cancel();
        _undoSnackBarTimer = null;
      });
    } catch (_) {}
  }

  /// Displays an auto-dismissing SnackBar guaranteed to disappear after the given duration (default 5s).
  static void showAutoDismissingSnackBar(
    BuildContext context,
    SnackBar snackBar, {
    Duration duration = const Duration(seconds: 5),
  }) {
    try {
      final messenger = ScaffoldMessenger.of(context);
      _undoSnackBarTimer?.cancel();
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(snackBar);
      _undoSnackBarTimer = Timer(duration, () {
        try {
          controller.close();
        } catch (_) {}
      });
      controller.closed.then((_) {
        _undoSnackBarTimer?.cancel();
        _undoSnackBarTimer = null;
      });
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
    // Push updated accounts list to Firestore immediately so deletions persist
    CloudSyncService.syncAccountsToCloud(accounts);
  }

  static Future<List<String>> loadAccounts(String username) async {
    return await AppDatabase.instance.loadAccounts(username);
  }

  static Future<void> saveTheme(String? username, String themeName) async {
    themeNameNotifier.value = themeName;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (username != null && username.isNotEmpty) {
        await prefs.setString('${_prefThemeKey}_$username', themeName);
      }
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

  // ---------------------------------------------------------------------------
  // Loans & Debts (Receivables & Payables)
  // ---------------------------------------------------------------------------
  static Future<void> saveLoan(String username, Loan loan) async {
    await AppDatabase.instance.saveLoan(username, loan);
    final loans = await AppDatabase.instance.loadLoans(username);
    loansNotifier.value = loans;

    // Schedule notification reminder if not settled
    if (!loan.isSettled) {
      await NotificationService.instance.scheduleLoanReminder(
        loan: loan,
        currencySymbol: currencyNotifier.value,
      );
    } else {
      await NotificationService.instance.cancelLoanReminder(loan.id);
    }
  }

  static Future<void> deleteLoan(String username, String loanId) async {
    await AppDatabase.instance.deleteLoan(username, loanId);
    await NotificationService.instance.cancelLoanReminder(loanId);
    final loans = await AppDatabase.instance.loadLoans(username);
    loansNotifier.value = loans;
  }

  static Future<void> toggleLoanSettled(String username, Loan loan) async {
    final updated = loan.copyWith(isSettled: !loan.isSettled);
    await saveLoan(username, updated);
  }

  // ---------------------------------------------------------------------------
  // Planned / Future Transactions & Recurring Automation
  // ---------------------------------------------------------------------------
  static Future<void> savePlannedTransaction(String username, PlannedTransaction plan) async {
    await AppDatabase.instance.savePlannedTransaction(username, plan);
    final plans = await AppDatabase.instance.loadPlannedTransactions(username);
    plannedTransactionsNotifier.value = plans;

    await NotificationService.instance.schedulePlannedTransactionReminder(
      plan: plan,
      currencySymbol: currencyNotifier.value,
    );
  }

  static Future<void> deletePlannedTransaction(String username, String planId) async {
    await AppDatabase.instance.deletePlannedTransaction(username, planId);
    await NotificationService.instance.cancelPlannedTransactionReminder(planId);
    final plans = await AppDatabase.instance.loadPlannedTransactions(username);
    plannedTransactionsNotifier.value = plans;
  }

  /// Immediately converts a planned transaction to active and moves it into the main ledger
  static Future<void> executePlannedTransactionNow(String username, PlannedTransaction plan) async {
    final newTx = plan.toActiveTransaction();
    final currentList = List<Transaction>.from(transactionsNotifier.value);
    currentList.removeWhere((t) => t.id == newTx.id);
    currentList.insert(0, newTx);
    currentList.sort((a, b) => b.date.compareTo(a.date));

    transactionsNotifier.value = currentList;
    await AppDatabase.instance.saveTransactions(username, currentList);
    await AppDatabase.instance.markPlannedTransactionProcessed(username, plan.id);
    await NotificationService.instance.cancelPlannedTransactionReminder(plan.id);

    final plans = await AppDatabase.instance.loadPlannedTransactions(username);
    plannedTransactionsNotifier.value = plans;
    CloudSyncService.syncTransactionToCloud(newTx);
  }

  /// Checks for due planned transactions and automatically records them into the active ledger
  static Future<void> checkAndProcessPlannedAndRecurring(String username) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final plans = await AppDatabase.instance.loadPlannedTransactions(username);
      final currentTxs = List<Transaction>.from(transactionsNotifier.value);
      bool txsUpdated = false;

      for (var plan in plans) {
        if (plan.date.isBefore(today) || plan.date.isAtSameMomentAs(today)) {
          final activeTx = plan.toActiveTransaction();
          if (!currentTxs.any((t) => t.id == activeTx.id)) {
            currentTxs.insert(0, activeTx);
            txsUpdated = true;
          }
          await AppDatabase.instance.markPlannedTransactionProcessed(username, plan.id);

          // Alert user via notification
          NotificationService.instance.showInstantAlert(
            title: 'Planned Transaction Added 📅',
            body: 'Your planned ${plan.isIncome ? "income" : "expense"} "${plan.title}" (${currencyNotifier.value}${plan.amount.toStringAsFixed(0)}) is recorded to your ledger!',
            id: (plan.id.hashCode.abs() % 50000) + 70000,
          );

          // If recurrence is active, schedule the next iteration
          if (plan.recurrence != 'None') {
            DateTime nextDate = plan.date;
            if (plan.recurrence == 'Daily') {
              nextDate = plan.date.add(const Duration(days: 1));
            } else if (plan.recurrence == 'Weekly') {
              nextDate = plan.date.add(const Duration(days: 7));
            } else if (plan.recurrence == 'Monthly') {
              nextDate = DateTime(plan.date.year, plan.date.month + 1, plan.date.day, plan.date.hour, plan.date.minute);
            } else if (plan.recurrence == 'Yearly') {
              nextDate = DateTime(plan.date.year + 1, plan.date.month, plan.date.day, plan.date.hour, plan.date.minute);
            }
            final nextPlan = plan.copyWith(
              id: 'plan_${DateTime.now().millisecondsSinceEpoch}_${plan.id.substring(max(0, plan.id.length - 4))}',
              date: nextDate,
              isProcessed: false,
              createdAt: DateTime.now(),
            );
            await AppDatabase.instance.savePlannedTransaction(username, nextPlan);
            await NotificationService.instance.schedulePlannedTransactionReminder(
              plan: nextPlan,
              currencySymbol: currencyNotifier.value,
            );
          }
        }
      }

      if (txsUpdated) {
        currentTxs.sort((a, b) => b.date.compareTo(a.date));
        transactionsNotifier.value = currentTxs;
        await AppDatabase.instance.saveTransactions(username, currentTxs);
      }

      plannedTransactionsNotifier.value = await AppDatabase.instance.loadPlannedTransactions(username);
    } catch (e) {
      debugPrint('checkAndProcessPlannedAndRecurring notice: $e');
    }
  }
}
