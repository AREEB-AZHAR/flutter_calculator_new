import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TourService {
  static const String tourHome = 'tally_tour_home_completed';
  static const String tourAccounts = 'tally_tour_accounts_completed';

  /// Checks if a tour has already been viewed and completed.
  static Future<bool> isTourCompleted(String tourKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(tourKey) ?? false;
    } catch (e) {
      debugPrint('TourService.isTourCompleted error: $e');
      return false;
    }
  }

  /// Marks a specific tour as completed.
  static Future<void> markTourCompleted(String tourKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(tourKey, true);
    } catch (e) {
      debugPrint('TourService.markTourCompleted error: $e');
    }
  }

  /// Resets all tour flags so user can replay the full onboarding guides.
  static Future<void> resetAllTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tourHome);
      await prefs.remove(tourAccounts);
    } catch (e) {
      debugPrint('TourService.resetAllTours error: $e');
    }
  }
}
