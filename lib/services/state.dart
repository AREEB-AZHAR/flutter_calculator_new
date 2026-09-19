import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';

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
  static final ValueNotifier<Color> avatarColorNotifier = ValueNotifier(const Color(0xFF8B5CF6));
  static final ValueNotifier<String> themeNameNotifier = ValueNotifier('Violet Night');
  static final ValueNotifier<List<SavingsGoal>> goalsNotifier = ValueNotifier([]);

  static Future<void> saveGoals(String username, List<SavingsGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goals_$username', jsonEncode(goals.map((e) => e.toJson()).toList()));
  }

  static Future<List<SavingsGoal>> loadGoals(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('goals_$username');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      return list.map((item) => SavingsGoal.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveTransactions(String username, List<Transaction> txs) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(txs.map((e) => e.toJson()).toList());
    await prefs.setString('tx_$username', encodedData);
  }

  static Future<List<Transaction>> loadTransactions(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('tx_$username');
    if (encodedData != null) {
      final List<dynamic> decodedList = jsonDecode(encodedData);
      return decodedList.map((item) => Transaction.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveBudgets(String username, Map<String, double> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('budgets_$username', jsonEncode(budgets));
  }

  static Future<Map<String, double>> loadBudgets(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('budgets_$username');
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    return {'Food & Dining': 500.0, 'Housing & Rent': 1500.0, 'Transportation': 300.0, 'Entertainment': 200.0};
  }

  static Future<void> saveAccounts(String username, List<String> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts_$username', jsonEncode(accounts));
  }

  static Future<List<String>> loadAccounts(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('accounts_$username');
    if (data != null) return List<String>.from(jsonDecode(data));
    return ['Main', 'Cash', 'Credit Card', 'Digital Wallet'];
  }

  static Future<void> saveTheme(String username, String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_$username', themeName);
  }

  static Future<String> loadTheme(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_$username') ?? 'Violet Night';
  }

  static Future<void> saveAvatarColor(String username, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('avatar_$username', color.toARGB32());
  }

  static Future<Color> loadAvatarColor(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt('avatar_$username');
    return val != null ? Color(val) : const Color(0xFF8B5CF6);
  }
}
