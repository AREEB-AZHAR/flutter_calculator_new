import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppThemePreset {
  final String name;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  const AppThemePreset(this.name, this.primary, this.secondary, this.surface, this.background);
}

const List<AppThemePreset> themePresets = [
  AppThemePreset('Violet Night',  Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFF151A22), Color(0xFF0B0E14)),
  AppThemePreset('Ocean Blue',    Color(0xFF3B82F6), Color(0xFF06B6D4), Color(0xFF0F172A), Color(0xFF020617)),
  AppThemePreset('Emerald Dark',  Color(0xFF10B981), Color(0xFFA78BFA), Color(0xFF0D1B1E), Color(0xFF060F11)),
  AppThemePreset('Rose Gold',     Color(0xFFF43F5E), Color(0xFFF59E0B), Color(0xFF1C1017), Color(0xFF0F090C)),
  AppThemePreset('Sunset Orange', Color(0xFFF97316), Color(0xFF3B82F6), Color(0xFF1A1410), Color(0xFF0D0A08)),
  AppThemePreset('Midnight Teal', Color(0xFF14B8A6), Color(0xFFE879F9), Color(0xFF0B1A1A), Color(0xFF060F0F)),
];

ThemeData buildAppTheme(String themeName) {
  final preset = themePresets.firstWhere((p) => p.name == themeName, orElse: () => themePresets.first);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: preset.background,
    colorScheme: ColorScheme.dark(
      primary: preset.primary,
      secondary: preset.secondary,
      surface: preset.surface,
    ),
    useMaterial3: true,
    fontFamily: defaultTargetPlatform == TargetPlatform.windows ? 'Segoe UI' : null,
  );
}

ThemeData buildDynamicTheme({Color? primary, Color? secondary}) {
  final primaryCol = primary ?? const Color(0xFF8B5CF6);
  final secondaryCol = secondary ?? const Color(0xFF10B981);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0E14),
    colorScheme: ColorScheme.dark(
      primary: primaryCol,
      secondary: secondaryCol,
      surface: const Color(0xFF151A22),
    ),
    useMaterial3: true,
    fontFamily: defaultTargetPlatform == TargetPlatform.windows ? 'Segoe UI' : null,
  );
}

const Map<String, IconData> categoryIcons = {
  'Food & Dining': Icons.fastfood,
  'Housing & Rent': Icons.home,
  'Transportation': Icons.directions_car,
  'Healthcare': Icons.local_hospital,
  'Entertainment': Icons.movie,
  'Education': Icons.school,
  'Salary': Icons.attach_money,
  'Investments': Icons.trending_up,
  'Shopping': Icons.shopping_cart,
  'Utilities': Icons.lightbulb,
  'Gifts': Icons.card_giftcard,
  'Travel': Icons.flight,
  'Other': Icons.category,
};

const Map<String, String> currencyOptions = {
  'USD (\$)': '\$',
  'EUR (€)': '€',
  'GBP (£)': '£',
  'PKR (₨)': '₨',
  'INR (₹)': '₹',
  'JPY (¥)': '¥',
  'CNY (¥)': '¥',
  'AED (د.إ)': 'د.إ',
  'SAR (﷼)': '﷼',
  'CAD (C\$)': 'C\$',
  'AUD (A\$)': 'A\$',
  'TRY (₺)': '₺',
  'BRL (R\$)': 'R\$',
};

String formatDate(DateTime date) {
  const List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
}

String formatTime(DateTime date) {
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final ampm = date.hour >= 12 ? 'PM' : 'AM';
  final min = date.minute.toString().padLeft(2, '0');
  return '$hour:$min $ampm';
}
