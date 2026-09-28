import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state.dart';

class TourService {
  static const String tourHome = 'tally_tour_home_completed';
  static const String tourAccounts = 'tally_tour_accounts_completed';

  static String _userTourKey(String baseKey, [String? username]) {
    final user = username ?? AppState.currentUser;
    if (user != null && user.isNotEmpty) {
      return '${baseKey}_$user';
    }
    return baseKey;
  }

  /// Checks if a tour has already been viewed and completed.
  static Future<bool> isTourCompleted(String tourKey, [String? username]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _userTourKey(tourKey, username);
      final completed = prefs.getBool(userKey);
      if (completed != null) return completed;
      // Fallback to legacy global key if user key is not set
      return prefs.getBool(tourKey) ?? false;
    } catch (e) {
      debugPrint('TourService.isTourCompleted error: $e');
      return false;
    }
  }

  /// Marks a specific tour as completed.
  static Future<void> markTourCompleted(String tourKey, [String? username]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _userTourKey(tourKey, username);
      await prefs.setBool(userKey, true);
    } catch (e) {
      debugPrint('TourService.markTourCompleted error: $e');
    }
  }

  /// Resets all tour flags so user can replay the full onboarding guides.
  static Future<void> resetAllTours([String? username]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userTourKey(tourHome, username));
      await prefs.remove(_userTourKey(tourAccounts, username));
      await prefs.remove(tourHome);
      await prefs.remove(tourAccounts);
    } catch (e) {
      debugPrint('TourService.resetAllTours error: $e');
    }
  }
}
