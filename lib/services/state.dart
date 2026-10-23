import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/goal_entry.dart';
import '../models/user_profile.dart';
import '../models/loan.dart';
import '../models/planned_transaction.dart';
import '../utils/constants.dart';
import 'database/app_database.dart';
import 'atomic_plans.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';
import 'monetization_service.dart';
import 'purchase_backend.dart';
import 'google_auth_service.dart';
import 'biometric_service.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';

class AppState {
  static String? _currentUser;
  static int _sessionGeneration = 0;
  static int get sessionGeneration => _sessionGeneration;
  static String? get currentUser => _currentUser;
  static set currentUser(String? value) {
    if (_currentUser != value) _sessionGeneration++;
    _currentUser = value;
  }

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
  /// If a user hasn't explicitly logged out, this immediately restores their chosen theme & palette
  /// for the dynamic splash/loading screen and app shell.
  static Future<void> initGlobalTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var savedTheme = prefs.getString(_prefThemeKey);

      if (savedTheme != null && themePresets.any((p) => p.name == savedTheme)) {
        themeNameNotifier.value = savedTheme;
        final preset = themePresets.firstWhere((p) => p.name == savedTheme);
        customPrimaryColorNotifier.value = preset.primary;
        customSecondaryColorNotifier.value = preset.secondary;
        avatarColorNotifier.value = preset.primary;
      } else {
        final ledger = themePresets.firstWhere((p) => p.name == 'Ledger');
        themeNameNotifier.value = ledger.name;
        customPrimaryColorNotifier.value = ledger.primary;
        customSecondaryColorNotifier.value = ledger.secondary;
        avatarColorNotifier.value = ledger.primary;
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

  /// Securely and immediately logs out the current user session.
  /// Transitions the UI instantly with a 60/120 FPS fade transition and clears all user data in memory.
  static Future<void> logout(BuildContext context) async {
    BiometricService.resetSessionPrompt();

    // 1. Immediately transition to LoginScreen with a crisp, butter-smooth 200ms fade transition
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
      ),
      (route) => false,
    );

    // 2. Perform session cleanup concurrently without blocking UI frame delivery
    await clearUserSession();
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
    BiometricService.resetSessionPrompt();
    DashboardScreen.hasAnimatedIntro = false;

    // Cancel all scheduled reminders from logged out session asynchronously in background
    unawaited(NotificationService.instance.cancelAllReminders());

    // Sign out from Google / Firebase to avoid credential bleed asynchronously in background
    unawaited(GoogleAuthService.signOut());

    // Reset fallback global theme in SharedPreferences to clean Ledger
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, 'Ledger');
      final ledger = themePresets.firstWhere((p) => p.name == 'Ledger');
      await prefs.setInt(_prefPrimaryColorKey, ledger.primary.toARGB32());
      await prefs.setInt(_prefSecondaryColorKey, ledger.secondary.toARGB32());
      await prefs.remove(_prefTextColorKey);
    } catch (_) {}
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
    final generation = sessionGeneration;
    bool sameSession() =>
        currentUser == username && generation == sessionGeneration;
    final db = AppDatabase.instance;

    // 1. Load monetization entitlements strictly scoped to this user
    await MonetizationService.loadUserEntitlements(username);

    // 2. Load user profile from SQLite database
    final profile = await db.loadProfile(username);
    if (!sameSession()) return;
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
      final preset = themePresets.firstWhere(
        (p) => p.name == effectiveTheme,
        orElse: () => themePresets.first,
      );
      pCol = preset.primary;
      sCol = preset.secondary;
      tCol = null;
    } else {
      // Pro user: heal legacy default if primaryColor matches old background or old default
      if (pCol.toARGB32() == 0xFF17493B || pCol.toARGB32() == 0xFF8B5CF6) {
        final preset = themePresets.firstWhere(
          (p) => p.name == effectiveTheme,
          orElse: () => themePresets.first,
        );
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

    // An unavailable verification server must not erase a paid user's saved palette.
    if (PurchaseSecurityPolicy.allowDevelopmentUnlocks ||
        MonetizationService.isPro) {
      await db.saveProfile(
        profile.copyWith(
          primaryColor: pCol,
          secondaryColor: sCol,
          textColor: tCol,
          clearTextColor: tCol == null,
          theme: effectiveTheme,
        ),
      );
    }

    final transactions = await db.loadTransactions(username);
    final budgets = await db.loadBudgets(username);
    final goals = await db.loadGoals(username);
    final accounts = await db.loadAccounts(username);
    final loans = await db.loadLoans(username);
    final plans = await db.loadPlannedTransactions(username);
    if (!sameSession()) return;
    transactionsNotifier.value = transactions;
    budgetsNotifier.value = budgets;
    goalsNotifier.value = goals;
    accountsNotifier.value = accounts;
    loansNotifier.value = loans;
    plannedTransactionsNotifier.value = plans;
    await checkGoalExpirations(username);
    await checkAndProcessPlannedAndRecurring(username);

    if (!sameSession()) return;
    // Optional platform work runs after the local vault is ready.
    unawaited(
      _scheduleSessionReminders(username, generation).catchError((
        Object error,
      ) {
        debugPrint('Reminder refresh failed: $error');
      }),
    );
    final initialPalette = [
      themeNameNotifier.value,
      customPrimaryColorNotifier.value,
      customSecondaryColorNotifier.value,
      customTextColorNotifier.value,
    ];
    unawaited(
      MonetizationService.verificationReady
          .then((_) async {
            bool unchanged() =>
                sameSession() &&
                MonetizationService.isPro &&
                themeNameNotifier.value == initialPalette[0] &&
                customPrimaryColorNotifier.value == initialPalette[1] &&
                customSecondaryColorNotifier.value == initialPalette[2] &&
                customTextColorNotifier.value == initialPalette[3];
            if (!unchanged()) return;
            final saved = await db.loadProfile(username);
            if (!unchanged()) return;
            final preset = themePresets
                .where((p) => p.name == saved.theme)
                .firstOrNull;
            if (preset == null) return;
            themeNameNotifier.value = preset.name;
            customPrimaryColorNotifier.value = saved.primaryColor;
            customSecondaryColorNotifier.value = saved.secondaryColor;
            customTextColorNotifier.value = saved.textColor;
            avatarColorNotifier.value = saved.primaryColor;
          })
          .catchError((Object error) {
            debugPrint('Deferred palette refresh failed: $error');
          }),
    );

    // Sync user's saved palette to SharedPreferences so next startup boots with this palette
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefThemeKey}_$username', effectiveTheme);
      await prefs.setInt('${_prefPrimaryColorKey}_$username', pCol.toARGB32());
      await prefs.setInt(
        '${_prefSecondaryColorKey}_$username',
        sCol.toARGB32(),
      );
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

  static Future<void> _scheduleSessionReminders(
    String username,
    int generation,
  ) async {
    bool sameSession() =>
        currentUser == username && sessionGeneration == generation;
    if (!sameSession()) return;
    final remindersOn = await NotificationService.instance.areRemindersEnabled(
      username,
    );
    if (!sameSession()) return;
    if (remindersOn) {
      await NotificationService.instance.scheduleAllDailyReminders();
      if (!sameSession()) return;
      await NotificationService.instance.scheduleGoalReminders(
        goalsNotifier.value,
        currencyNotifier.value,
      );
      for (final loan in List<Loan>.of(loansNotifier.value)) {
        if (!sameSession()) return;
        if (!loan.isSettled) {
          await NotificationService.instance.scheduleLoanReminder(
            loan: loan,
            currencySymbol: currencyNotifier.value,
          );
        }
      }
      for (final plan in List<PlannedTransaction>.of(
        plannedTransactionsNotifier.value,
      )) {
        if (!sameSession()) return;
        await NotificationService.instance.schedulePlannedTransactionReminder(
          plan: plan,
          currencySymbol: currencyNotifier.value,
        );
      }
    } else {
      await NotificationService.instance.cancelAllReminders();
    }
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
      await prefs.setString('${_prefThemeKey}_${profile.username}', themeNameNotifier.value);
      await prefs.setInt('${_prefPrimaryColorKey}_${profile.username}', updatedProfile.primaryColor.toARGB32());
      await prefs.setInt('${_prefSecondaryColorKey}_${profile.username}', updatedProfile.secondaryColor.toARGB32());
      if (updatedProfile.textColor != null) {
        await prefs.setInt('${_prefTextColorKey}_${profile.username}', updatedProfile.textColor!.toARGB32());
      } else {
        await prefs.remove('${_prefTextColorKey}_${profile.username}');
      }
      await prefs.setString('${_prefCurrencyKey}_${profile.username}', updatedProfile.currency);

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
    await checkGoalExpirations(username);
    final remindersOn = await NotificationService.instance.areRemindersEnabled(username);
    if (remindersOn) {
      NotificationService.instance.scheduleGoalReminders(
        goalsNotifier.value,
        currencyNotifier.value,
      );
    }
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
    final username = currentUser;
    final generation = sessionGeneration;
    final currentList = List<Transaction>.from(transactionsNotifier.value);
    final originalIndex = currentList.indexWhere((t) => t.id == tx.id);
    currentList.removeWhere((t) => t.id == tx.id);
    transactionsNotifier.value = currentList;
    if (currentUser != null) {
      AppDatabase.instance
          .deleteSingleTransaction(tx.id, username: username)
          .then((_) {
            if (currentUser == username && sessionGeneration == generation) {
              unawaited(CloudSyncService.sync(username!));
            }
          });
      if (tx.category == 'Savings Goal') {
        AppDatabase.instance
            .deleteGoalEntryByTransactionId(username!, tx.id)
            .then((_) async {
              final refreshedGoals = await AppDatabase.instance.loadGoals(username);
              if (currentUser != username || sessionGeneration != generation) return;
              goalsNotifier.value = refreshedGoals;
              await checkGoalExpirations(username);
              if (currentUser != username || sessionGeneration != generation) return;
              NotificationService.instance.scheduleGoalReminders(
                goalsNotifier.value,
                currencyNotifier.value,
              );
            });
      }
    }

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
              if (currentUser != username || sessionGeneration != generation) {
                return;
              }
              final restoredList = List<Transaction>.from(
                transactionsNotifier.value,
              );
              if (!restoredList.any((t) => t.id == tx.id)) {
                if (originalIndex >= 0 &&
                    originalIndex <= restoredList.length) {
                  restoredList.insert(originalIndex, tx);
                } else {
                  restoredList.add(tx);
                }
                restoredList.sort((a, b) => b.date.compareTo(a.date));
                transactionsNotifier.value = restoredList;
                if (currentUser != null) {
                  AppDatabase.instance.insertTransaction(username!, tx).then((
                    _,
                  ) {
                    if (currentUser == username &&
                        sessionGeneration == generation) {
                      unawaited(CloudSyncService.sync(username));
                    }
                  });
                  if (tx.category == 'Savings Goal') {
                    AppDatabase.instance.loadGoals(username).then((refreshedGoals) {
                      if (currentUser != username || sessionGeneration != generation) return;
                      goalsNotifier.value = refreshedGoals;
                      NotificationService.instance.scheduleGoalReminders(
                        refreshedGoals,
                        currencyNotifier.value,
                      );
                    });
                  }
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

  /// Safely deletes a savings goal using soft-delete logic (archive if >10% or completed),
  /// and displays a SnackBar with an 'Undo' option.
  static void deleteGoalWithUndo(BuildContext context, SavingsGoal goal) {
    final username = currentUser;
    final generation = sessionGeneration;
    final currentGoals = List<SavingsGoal>.from(goalsNotifier.value);
    final originalIndex = currentGoals.indexWhere((g) => g.id == goal.id);
    currentGoals.removeWhere((g) => g.id == goal.id);
    goalsNotifier.value = currentGoals;
    if (currentUser != null) {
      AppDatabase.instance.softDeleteGoal(username!, goal.id).then((_) {
        if (currentUser == username && sessionGeneration == generation) {
          unawaited(CloudSyncService.sync(username));
        }
      });
    }
    // Cancel goal reminders immediately and purge orphaned alarms
    unawaited(NotificationService.instance.cancelGoalReminders(goal.id));
    unawaited(
      NotificationService.instance.scheduleGoalReminders(
        currentGoals,
        currencyNotifier.value,
      ),
    );

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
              if (currentUser != username || sessionGeneration != generation) {
                return;
              }
              final restoredGoals = List<SavingsGoal>.from(goalsNotifier.value);
              if (!restoredGoals.any((g) => g.id == goal.id)) {
                if (originalIndex >= 0 &&
                    originalIndex <= restoredGoals.length) {
                  restoredGoals.insert(originalIndex, goal);
                } else {
                  restoredGoals.add(goal);
                }
                goalsNotifier.value = restoredGoals;
                if (currentUser != null) {
                  // Re-upsert the goal (un-archive or re-insert)
                  AppDatabase.instance
                      .upsertGoal(username!, goal.copyWith(isArchived: false))
                      .then((_) {
                        if (currentUser == username &&
                            sessionGeneration == generation) {
                          unawaited(CloudSyncService.sync(username));
                        }
                      });
                }
                NotificationService.instance.scheduleGoalReminders(
                  restoredGoals,
                  currencyNotifier.value,
                );
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

  // ---------------------------------------------------------------------------
  // Goal Entry CRUD – deposits into savings goals
  // ---------------------------------------------------------------------------

  /// Adds a deposit to a savings goal, creates a GoalEntry, and refreshes state.
  static Future<void> addGoalEntry(String username, GoalEntry entry) async {
    await AppDatabase.instance.addGoalEntry(username, entry);
    // Reload goals to get updated saved amounts
    goalsNotifier.value = await AppDatabase.instance.loadGoals(username);
    await checkGoalExpirations(username);
    final remindersOn = await NotificationService.instance.areRemindersEnabled(username);
    if (remindersOn) {
      NotificationService.instance.scheduleGoalReminders(
        goalsNotifier.value,
        currencyNotifier.value,
      );
    }
    CloudSyncService.syncGoalsToCloud(goalsNotifier.value);
  }

  /// Updates an existing goal entry and refreshes state.
  static Future<void> updateGoalEntry(String username, GoalEntry entry) async {
    await AppDatabase.instance.updateGoalEntry(username, entry);
    goalsNotifier.value = await AppDatabase.instance.loadGoals(username);
    await checkGoalExpirations(username);
    final remindersOn = await NotificationService.instance.areRemindersEnabled(username);
    if (remindersOn) {
      NotificationService.instance.scheduleGoalReminders(
        goalsNotifier.value,
        currencyNotifier.value,
      );
    }
    CloudSyncService.syncGoalsToCloud(goalsNotifier.value);
  }

  /// Deletes a goal entry and refreshes state.
  static Future<void> deleteGoalEntry(String username, String entryId, String goalId) async {
    await AppDatabase.instance.deleteGoalEntry(username, entryId, goalId);
    goalsNotifier.value = await AppDatabase.instance.loadGoals(username);
    await checkGoalExpirations(username);
    final remindersOn = await NotificationService.instance.areRemindersEnabled(username);
    if (remindersOn) {
      NotificationService.instance.scheduleGoalReminders(
        goalsNotifier.value,
        currencyNotifier.value,
      );
    }
    CloudSyncService.syncGoalsToCloud(goalsNotifier.value);
  }

  /// Removes any goal entry linked to a transaction and refreshes state.
  static Future<void> removeGoalEntryForTransaction(String username, String txId) async {
    await AppDatabase.instance.deleteGoalEntryByTransactionId(username, txId);
    goalsNotifier.value = await AppDatabase.instance.loadGoals(username);
    await checkGoalExpirations(username);
    final remindersOn = await NotificationService.instance.areRemindersEnabled(username);
    if (remindersOn) {
      NotificationService.instance.scheduleGoalReminders(
        goalsNotifier.value,
        currencyNotifier.value,
      );
    }
    CloudSyncService.syncGoalsToCloud(goalsNotifier.value);
  }

  /// Checks and marks expired/completed goals, triggers recurring cycles if enabled.
  static Future<void> checkGoalExpirations(String username) async {
    final goals = List<SavingsGoal>.from(goalsNotifier.value);
    bool changed = false;

    for (int i = 0; i < goals.length; i++) {
      final g = goals[i];
      // Mark completed goals
      if (g.saved >= g.target && !g.isCompleted) {
        goals[i] = g.copyWith(isCompleted: true);
        await AppDatabase.instance.updateGoalStatus(username, g.id, isCompleted: true);
        changed = true;
      }
      // Mark expired goals as failed
      if (g.isExpired && !g.isFailed) {
        goals[i] = g.copyWith(isFailed: true);
        await AppDatabase.instance.updateGoalStatus(username, g.id, isFailed: true);
        changed = true;
      }
    }

    if (changed) {
      goalsNotifier.value = List.from(goals);
    }
  }

  /// Calculates total vault savings (sum of all active goals' saved amounts).
  static double get totalVaultSavings {
    return goalsNotifier.value
        .where((g) => !g.isArchived)
        .fold(0.0, (sum, g) => sum + g.saved);
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
      final saved = (username != null && username.isNotEmpty)
          ? prefs.getString('${_prefThemeKey}_$username') ?? prefs.getString(_prefThemeKey)
          : prefs.getString(_prefThemeKey);
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
      NotificationService.instance.scheduleGoalReminders(
        goalsNotifier.value,
        currency,
      );
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

  /// Both manual promotion and automatic processing use the same atomic writer.
  static Future<bool> executePlannedTransactionNow(
    String username,
    PlannedTransaction plan,
  ) async {
    final generation = sessionGeneration;
    final db = await AppDatabase.instance.database;
    final result = await AtomicPlans(
      db,
    ).process(username, plan.id, now: DateTime.now(), force: true);
    if (result != null) {
      await _publishProcessedPlans(username, generation, [result]);
      if (currentUser == username && sessionGeneration == generation) unawaited(CloudSyncService.sync(username));
    }
    return result != null;
  }

  static Future<void> checkAndProcessPlannedAndRecurring(
    String username,
  ) async {
    final generation = sessionGeneration;
    final db = await AppDatabase.instance.database;
    final results = await AtomicPlans(
      db,
    ).processDue(username, now: DateTime.now());
    // Nothing changed: avoid rereading the whole ledger and rescheduling every plan.
    if (results.isEmpty) return;
    // Persistence failures propagate. A failed occurrence rolls back and stays due.
    await _publishProcessedPlans(username, generation, results, notify: true);
  }

  static Future<void> _publishProcessedPlans(
    String username,
    int generation,
    List<ProcessedPlan> results, {
    bool notify = false,
  }) async {
    final txs = await AppDatabase.instance.loadTransactions(username);
    final plans = await AppDatabase.instance.loadPlannedTransactions(username);
    if (currentUser != username || sessionGeneration != generation) return;
    transactionsNotifier.value = txs;
    plannedTransactionsNotifier.value = plans;
    // Notification failures cannot undo or prevent committed ledger processing.
    if (notify && results.isNotEmpty) {
      try {
        await NotificationService.instance.showInstantAlert(
          title: 'Planned transactions recorded',
          body: results.length == 1
              ? '"${results.single.plan.title}" was added to your ledger.'
              : '${results.length} planned transactions were added to your ledger.',
        );
      } catch (e) {
        debugPrint('Committed plan notification notice: $e');
      }
    }
    for (final result in results) {
      if (currentUser != username || sessionGeneration != generation) return;
      try {
        await NotificationService.instance.cancelPlannedTransactionReminder(
          result.plan.id,
        );
      } catch (e) {
        debugPrint('Committed plan reminder cleanup notice: $e');
      }
    }
    for (final plan in plans) {
      if (currentUser != username || sessionGeneration != generation) return;
      try {
        await NotificationService.instance.schedulePlannedTransactionReminder(
          plan: plan,
          currencySymbol: currencyNotifier.value,
        );
      } catch (e) {
        debugPrint('Committed plan reminder scheduling notice: $e');
      }
    }
  }
}
