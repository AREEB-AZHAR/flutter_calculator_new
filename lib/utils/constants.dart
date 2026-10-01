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
  AppThemePreset('Ledger',        Color(0xFFE4572E), Color(0xFFF6F0E1), Color(0xFF103A2E), Color(0xFF17493B)),
  AppThemePreset('Paper',         Color(0xFFE4572E), Color(0xFF17493B), Color(0xFFFFFFFF), Color(0xFFF6F0E1)),
  AppThemePreset('Ink',           Color(0xFFE8A13C), Color(0xFFE4572E), Color(0xFF23231D), Color(0xFF191915)),
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

ThemeData buildDynamicTheme({Color? primary, Color? secondary, Color? textColor, String? themeName}) {
  final name = themeName ?? 'Ledger';
  final preset = themePresets.firstWhere((p) => p.name == name, orElse: () => themePresets.first);
  final isLight = name == 'Paper';

  // Protect against primary or secondary matching background or surface color (e.g. from legacy database profiles)
  var primaryCol = primary ?? preset.primary;
  var secondaryCol = secondary ?? preset.secondary;
  if (primaryCol.toARGB32() == preset.background.toARGB32() ||
      primaryCol.toARGB32() == preset.surface.toARGB32() ||
      (name == 'Ink' && (primaryCol.toARGB32() == 0xFFFFFFFF || primaryCol.toARGB32() == 0xFFF6F0E1 || primaryCol.toARGB32() == 0xFFF3EDE0)) ||
      (name == 'Paper' && (primaryCol.toARGB32() == 0xFFFFFFFF || primaryCol.toARGB32() == 0xFFF6F0E1 || primaryCol.toARGB32() == 0xFFF3EDE0))) {
    primaryCol = preset.primary;
  }
  if (secondaryCol.toARGB32() == preset.background.toARGB32() ||
      secondaryCol.toARGB32() == preset.surface.toARGB32()) {
    secondaryCol = preset.secondary;
  }

  // Background matches the icon background across all themes
  final bg = preset.background;

  // Surface/card color
  final surface = preset.surface;

  // Text colors:
  // If user explicitly set textColor, use it! Otherwise:
  // Ink: uses amber slash color (#E8A13C) for text per user request
  // Paper: uses forest green stroke mark (#17493B) for crisp contrast on cream paper
  // Ledger: uses chalk cream stroke mark (#F6F0E1) for high-contrast on forest green
  final onSurface = textColor ?? (name == 'Paper'
      ? const Color(0xFF17493B)
      : (name == 'Ink'
          ? const Color(0xFFE8A13C)
          : (name == 'Ledger'
              ? const Color(0xFFF6F0E1)
              : Colors.white)));

  final onSurfaceVariant = (name == 'Ink' && textColor == null)
      ? const Color(0xFFF3EDE0).withValues(alpha: 0.8)
      : onSurface.withValues(alpha: 0.7);
  final brightness = isLight ? Brightness.light : Brightness.dark;

  // Contrast-aware foreground colors for buttons and floating action buttons
  final onPrimary = primaryCol.computeLuminance() > 0.5 ? const Color(0xFF152A22) : Colors.white;
  final onSecondary = secondaryCol.computeLuminance() > 0.5 ? const Color(0xFF152A22) : Colors.white;

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primaryCol,
      onPrimary: onPrimary,
      secondary: secondaryCol,
      onSecondary: onSecondary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    useMaterial3: true,
    fontFamily: defaultTargetPlatform == TargetPlatform.windows ? 'Segoe UI' : null,
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: onSurface),
      bodyMedium: TextStyle(color: onSurface),
      bodySmall: TextStyle(color: onSurfaceVariant),
      labelLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: onSurfaceVariant),
      labelSmall: TextStyle(color: onSurfaceVariant),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: onSurface,
      elevation: 0,
      titleTextStyle: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: onSurface.withValues(alpha: 0.12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: onSurfaceVariant, fontSize: 14),
    ),
    listTileTheme: ListTileThemeData(
      textColor: onSurface,
      iconColor: primaryCol,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryCol,
        foregroundColor: onPrimary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryCol,
      foregroundColor: onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primaryCol.withValues(alpha: 0.2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surface,
      filled: true,
      labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: onSurface.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: onSurface.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryCol, width: 2),
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
  'Savings Goal': Icons.savings,
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

String formatDateWithYear(DateTime date) {
  const List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatTime(DateTime date) {
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final ampm = date.hour >= 12 ? 'PM' : 'AM';
  final min = date.minute.toString().padLeft(2, '0');
  return '$hour:$min $ampm';
}
