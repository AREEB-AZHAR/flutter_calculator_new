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
  AppThemePreset('Ledger',        Color(0xFF17493B), Color(0xFFE4572E), Color(0xFFFFFFFF), Color(0xFFFBF9F5)),
  AppThemePreset('Paper',         Color(0xFF17493B), Color(0xFFE4572E), Color(0xFFF0EAE1), Color(0xFFF6F0E1)),
  AppThemePreset('Ink',           Color(0xFFE8A13C), Color(0xFFE4572E), Color(0xFF20201A), Color(0xFF191915)),
  AppThemePreset('Violet Night',  Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFF151A22), Color(0xFF0B0E14)),
  AppThemePreset('Ocean Blue',    Color(0xFF3B82F6), Color(0xFF06B6D4), Color(0xFF0F172A), Color(0xFF020617)),
  AppThemePreset('Emerald Dark',  Color(0xFF10B981), Color(0xFFA78BFA), Color(0xFF0D1B1E), Color(0xFF060F11)),
  AppThemePreset('Rose Gold',     Color(0xFFF43F5E), Color(0xFFF59E0B), Color(0xFF1C1017), Color(0xFF0F090C)),
  AppThemePreset('Sunset Orange', Color(0xFFF97316), Color(0xFF3B82F6), Color(0xFF1A1410), Color(0xFF0D0A08)),
  AppThemePreset('Midnight Teal', Color(0xFF14B8A6), Color(0xFFE879F9), Color(0xFF0B1A1A), Color(0xFF060F0F)),
];

ThemeData buildAppTheme(String themeName) {
  final preset = themePresets.firstWhere((p) => p.name == themeName, orElse: () => themePresets.first);
  return buildDynamicTheme(
    primary: preset.primary,
    secondary: preset.secondary,
    themeName: preset.name,
  );
}

ThemeData buildDynamicTheme({Color? primary, Color? secondary, String? themeName}) {
  final name = themeName ?? 'Ledger';
  final isDark = name == 'Ink' ||
      name == 'Violet Night' ||
      name == 'Ocean Blue' ||
      name == 'Emerald Dark' ||
      name == 'Rose Gold' ||
      name == 'Sunset Orange' ||
      name == 'Midnight Teal';

  final primaryCol = primary ?? const Color(0xFF17493B);
  final secondaryCol = secondary ?? const Color(0xFFE4572E);

  final brightness = isDark ? Brightness.dark : Brightness.light;
  final bg = isDark
      ? (name == 'Ink' ? const Color(0xFF191915) : const Color(0xFF0B0E14))
      : (name == 'Paper' ? const Color(0xFFF6F0E1) : const Color(0xFFFBF9F5));

  final surface = isDark
      ? (name == 'Ink' ? const Color(0xFF20201A) : const Color(0xFF151A22))
      : (name == 'Paper' ? const Color(0xFFF0EAE1) : Colors.white);

  final onSurface = isDark
      ? (name == 'Ink' ? const Color(0xFFF3EDE0) : Colors.white)
      : const Color(0xFF152A22);

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primaryCol,
      onPrimary: const Color(0xFFF6F0E1),
      secondary: secondaryCol,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    useMaterial3: true,
    fontFamily: defaultTargetPlatform == TargetPlatform.windows ? 'Segoe UI' : null,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
      ),
    ),
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
