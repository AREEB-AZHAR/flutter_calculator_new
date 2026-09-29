import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/widgets/tally_brand_painters.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dynamic Theme Persistence & User Session Tests', () {
    test('initGlobalTheme preserves user configured theme on reboot without logout', () async {
      SharedPreferences.setMockInitialValues({
        'tally_active_theme': 'Paper',
        'tally_primary_color': 0xFF123456,
        'tally_secondary_color': 0xFF654321,
      });

      await AppState.initGlobalTheme();

      expect(AppState.themeNameNotifier.value, 'Paper');
      expect(AppState.customPrimaryColorNotifier.value.toARGB32(), 0xFF123456);
      expect(AppState.customSecondaryColorNotifier.value.toARGB32(), 0xFF654321);
    });

    test('clearUserSession resets theme to Ledger defaults in memory and SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'tally_active_theme': 'Ocean Blue',
        'tally_primary_color': 0xFF00FFCC,
        'tally_secondary_color': 0xFFFF007F,
      });
      await AppState.initGlobalTheme();
      expect(AppState.themeNameNotifier.value, 'Ocean Blue');

      await AppState.clearUserSession();

      expect(AppState.themeNameNotifier.value, 'Ledger');
      expect(AppState.customPrimaryColorNotifier.value.toARGB32(), 0xFFE4572E);
      expect(AppState.customSecondaryColorNotifier.value.toARGB32(), 0xFFF6F0E1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tally_active_theme'), 'Ledger');
      expect(prefs.getInt('tally_primary_color'), 0xFFE4572E);
      expect(prefs.getInt('tally_secondary_color'), 0xFFF6F0E1);
    });

    test('New registered user is initialized with Ledger theme by default in profiles', () async {
      final db = await AppDatabase.instance.database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final username = 'user_$timestamp';
      final email = 'user_$timestamp@example.com';

      final success = await AppDatabase.instance.registerUser(
        username: username,
        password: 'Password123!',
        email: email,
      );

      expect(success, isTrue);
      final res = await db.query('profiles', where: 'username = ?', whereArgs: [username]);
      expect(res.isNotEmpty, isTrue);
      expect(res.first['theme'], 'Ledger');
    });
  });

  group('Dynamic Splash Tally Painter Rendering', () {
    testWidgets('TallyIconPainter renders with custom palette colors', (tester) async {
      AppState.themeNameNotifier.value = 'Ink';
      AppState.customPrimaryColorNotifier.value = const Color(0xFF6C5CE7);
      AppState.customSecondaryColorNotifier.value = const Color(0xFFA29BFE);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: TallyIconPainter(
                    stroke1Progress: 1.0,
                    stroke2Progress: 1.0,
                    stroke3Progress: 1.0,
                    stroke4Progress: 1.0,
                    slashProgress: 1.0,
                    bgColor: const Color(0xFF191915),
                    strokeColor: const Color(0xFFF3EDE0),
                    slashColor: AppState.customPrimaryColorNotifier.value,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
