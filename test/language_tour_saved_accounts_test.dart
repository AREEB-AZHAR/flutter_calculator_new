import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_tracker/services/language_service.dart';
import 'package:balance_tracker/widgets/feature_tour_dialog.dart';
import 'package:balance_tracker/models/saved_account_info.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/screens/saved_accounts_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Multilingual Dynamic Translation Tests', () {
    test('Translates navigation tabs and dashboard keys across all 7 languages', () async {
      for (final lang in ['en', 'es', 'fr', 'de', 'ur', 'ar', 'hi']) {
        await LanguageService.setLanguage(lang);
        expect(LanguageService.tr('nav_home').isNotEmpty, isTrue);
        expect(LanguageService.tr('nav_insights').isNotEmpty, isTrue);
        expect(LanguageService.tr('nav_goals').isNotEmpty, isTrue);
        expect(LanguageService.tr('nav_accounts').isNotEmpty, isTrue);
        expect(LanguageService.tr('nav_profile').isNotEmpty, isTrue);
        expect(LanguageService.tr('total_balance').isNotEmpty, isTrue);
        expect(LanguageService.tr('saved_accounts_title').isNotEmpty, isTrue);
        expect(LanguageService.tr('welcome_back').isNotEmpty, isTrue);
        expect(LanguageService.tr('login_button').isNotEmpty, isTrue);
      }
      // Reset back to English
      await LanguageService.setLanguage('en');
    });

    test('English dictionary matches expected localized terms', () async {
      await LanguageService.setLanguage('en');
      expect(LanguageService.tr('total_balance'), 'Total Balance');
      expect(LanguageService.tr('saved_accounts_title'), 'Saved Accounts');
      expect(LanguageService.tr('welcome_back'), 'Welcome Back');
      expect(LanguageService.tr('login_button'), 'Login to Tally');
    });

    test('Spanish dictionary translates keys correctly', () async {
      await LanguageService.setLanguage('es');
      expect(LanguageService.tr('nav_home'), 'Inicio');
      expect(LanguageService.tr('total_balance'), 'Saldo Total');
      expect(LanguageService.tr('saved_accounts_title'), 'Cuentas Guardadas');
      expect(LanguageService.tr('welcome_back'), 'Bienvenido de Nuevo');
      await LanguageService.setLanguage('en');
    });
  });

  group('Feature Tour Concurrency & Deduplication Tests', () {
    testWidgets('Second concurrent tour call is rejected when tour is active', (tester) async {
      bool dialogBuilt = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    // Trigger first tour
                    showFeatureTour(
                      context,
                      tourTitle: 'First Tour',
                      tourKey: 'tour_test_1',
                      steps: [
                        const TourStep(
                          title: 'First Step',
                          description: 'First tour step description',
                          icon: Icons.star,
                        ),
                      ],
                    );
                    dialogBuilt = true;

                    // Immediately trigger second tour concurrent attempt
                    await showFeatureTour(
                      context,
                      tourTitle: 'Second Tour',
                      tourKey: 'tour_test_2',
                      steps: [
                        const TourStep(
                          title: 'Duplicate Step',
                          description: 'Should not show',
                          icon: Icons.error,
                        ),
                      ],
                    );
                  },
                  child: const Text('Launch Tour'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Launch Tour'));
      await tester.pumpAndSettle();

      expect(dialogBuilt, isTrue);
      expect(find.text('First Step'), findsOneWidget);
      // The duplicate should not appear
      expect(find.text('Duplicate Step'), findsNothing);

      // Dismiss the active tour via 'Got it!'
      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();

      expect(find.text('First Step'), findsNothing);
    });
  });

  group('Saved Accounts Database & Model Tests', () {
    final db = AppDatabase.instance;
    final testUser = 'saved_acc_tester_${DateTime.now().millisecondsSinceEpoch}';

    setUpAll(() async {
      await db.database;
      await db.registerUser(
        username: testUser,
        password: 'Password123!@#',
        email: '$testUser@test.com',
      );
    });

    test('getAllSavedAccounts retrieves newly registered user info', () async {
      final accounts = await db.getAllSavedAccounts();
      expect(accounts.isNotEmpty, isTrue);
      final found = accounts.where((a) => a.username.toLowerCase() == testUser.toLowerCase());
      expect(found.isNotEmpty, isTrue);
      final acc = found.first;
      expect(acc.email, '$testUser@test.com');
      expect(acc.isGoogleAccount, isFalse);
    });

    test('SavedAccountInfo model attributes serialize accurately', () {
      final info = SavedAccountInfo(
        username: 'alice',
        email: 'alice@example.com',
        displayName: 'Alice In Wonderland',
        photoPath: null,
        primaryColor: Colors.teal.toARGB32(),
        isBiometricEnabled: true,
        isGoogleAccount: false,
        createdAt: '2026-10-01',
      );

      expect(info.username, 'alice');
      expect(info.displayName, 'Alice In Wonderland');
      expect(info.isBiometricEnabled, isTrue);
      expect(info.isGoogleAccount, isFalse);
    });

    testWidgets('SavedAccountsScreen renders app bar and responds without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SavedAccountsScreen(),
        ),
      );

      await tester.pump();
      expect(find.text(LanguageService.tr('saved_accounts_title')), findsOneWidget);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.byType(SavedAccountsScreen), findsOneWidget);
    });
  });
}
