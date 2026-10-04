import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/language_service.dart';
import 'package:balance_tracker/screens/main_nav_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Localization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppState.currentUser = 'test_user';
      LanguageService.setLanguage('en');
    });

    test('All 7 supported languages exist with codes and names', () {
      final langs = LanguageService.supportedLanguages;
      expect(langs.length, 7);
      final codes = langs.map((l) => l.code).toSet();
      expect(codes, containsAll(['en', 'es', 'fr', 'de', 'ur', 'ar', 'hi']));
    });

    test('All 7 languages contain essential UI and screen localization keys', () {
      final essentialKeys = [
        'app_title',
        'nav_home',
        'nav_insights',
        'nav_goals',
        'nav_accounts',
        'nav_profile',
        'balance',
        'total_balance',
        'income',
        'expense',
        'recent_transactions',
        'add_transaction',
        'savings_vault',
        'budget_limits',
        'profile_title',
        'settings',
        'app_account_settings',
        'interactive_tours_section',
        'replay_tours',
        'pro_membership_section',
        'brand_palettes_section',
        'theme_studio_title',
        'currency_symbol',
        'app_language',
        'select_language',
        'select_currency',
        'screen_lock',
        'logout',
        'who_owes_you',
        'who_do_you_owe',
        'title_purpose',
        'reminder_due_date_time',
        'save_loan',
        'add_first_loan',
        'delete_loan_title',
        'delete_loan_confirm',
        'loan_record_deleted',
        'mark_as_unsettled',
        'mark_as_settled',
        'add_new_account',
        'accounts_tour',
        'add_loan_debt',
        'wallets_and_accounts',
        'loans_and_debts',
        'all_transactions_prefix',
        'transactions_prefix',
        'analytics_prefix',
        'overall_flow_and_analytics',
        'due_in',
        'clear_filters',
        'no_loans_in_filter',
        'executive_financial_vitals',
        'lifetime_inflow',
        'lifetime_outflow',
        'retained_wealth',
        'needs_vs_wants',
        'top_spending_drivers',
        'no_expense_recorded',
        'peak_single_outflow',
        'open_settings',
        'spending_persona',
        'savings_rate',
      ];

      for (final lang in LanguageService.supportedLanguages) {
        LanguageService.setLanguage(lang.code);
        for (final key in essentialKeys) {
          final translated = LanguageService.tr(key);
          expect(
            translated.isNotEmpty,
            isTrue,
            reason: 'Key "$key" should not be empty for language "${lang.code}"',
          );
          expect(
            translated,
            isNot(equals(key)),
            reason: 'Key "$key" should have an actual translation for language "${lang.code}"',
          );
        }
      }
    });

    test('trCategory translates standard categories across languages', () {
      const dbCategories = [
        'Food & Dining',
        'Salary',
        'Shopping',
        'Transportation',
        'Bills & Utilities',
        'Entertainment',
        'Healthcare',
        'General',
      ];

      LanguageService.setLanguage('es');
      for (final cat in dbCategories) {
        final tr = LanguageService.trCategory(cat);
        expect(tr.isNotEmpty, isTrue);
      }
      expect(LanguageService.trCategory('Food & Dining'), 'Comida y Restaurantes');
      expect(LanguageService.trCategory('Salary'), 'Salario');

      LanguageService.setLanguage('ur');
      expect(LanguageService.trCategory('Food & Dining'), 'کھانا پینا اور ضیافت');
      expect(LanguageService.trCategory('Salary'), 'تنخواہ');

      LanguageService.setLanguage('ar');
      expect(LanguageService.trCategory('Food & Dining'), 'طعام ومطاعم');
      expect(LanguageService.trCategory('Salary'), 'راتب');

      LanguageService.setLanguage('hi');
      expect(LanguageService.trCategory('Food & Dining'), 'खान-पान और भोजन');
      expect(LanguageService.trCategory('Salary'), 'वेतन');
    });

    test('trRecurrence translates recurrence intervals across languages', () {
      LanguageService.setLanguage('en');
      expect(LanguageService.trRecurrence('Daily'), 'Daily');

      LanguageService.setLanguage('es');
      expect(LanguageService.trRecurrence('Daily'), 'Diario');
      expect(LanguageService.trRecurrence('Monthly'), 'Mensual');

      LanguageService.setLanguage('ur');
      expect(LanguageService.trRecurrence('Daily'), 'روزانہ');
      expect(LanguageService.trRecurrence('Monthly'), 'ماہانہ');

      LanguageService.setLanguage('ar');
      expect(LanguageService.trRecurrence('Daily'), 'يومي');
      expect(LanguageService.trRecurrence('Monthly'), 'شهري');

      LanguageService.setLanguage('hi');
      expect(LanguageService.trRecurrence('Daily'), 'दैनिक');
      expect(LanguageService.trRecurrence('Monthly'), 'मासिक');
    });

    test('isRtl returns true only for Arabic and Urdu', () {
      expect(LanguageService.isLanguageRtl('ur'), isTrue);
      expect(LanguageService.isLanguageRtl('ar'), isTrue);
      expect(LanguageService.isLanguageRtl('en'), isFalse);
      expect(LanguageService.isLanguageRtl('es'), isFalse);
      expect(LanguageService.isLanguageRtl('fr'), isFalse);
      expect(LanguageService.isLanguageRtl('de'), isFalse);
      expect(LanguageService.isLanguageRtl('hi'), isFalse);
    });

    testWidgets('MainNavScreen locks NavigationBar textDirection to LTR even in RTL mode', (tester) async {
      LanguageService.setLanguage('ur');

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Directionality widget wrapping the NavigationBar
      final navBarFinder = find.byType(NavigationBar);
      expect(navBarFinder, findsOneWidget);

      final directionalityFinder = find.ancestor(
        of: navBarFinder,
        matching: find.byType(Directionality),
      );
      expect(directionalityFinder, findsWidgets);

      final nearestDirectionality = tester.widget<Directionality>(directionalityFinder.first);
      expect(nearestDirectionality.textDirection, TextDirection.ltr);
    });

    test('All 7 languages have 100% key parity with English dictionary (417 keys each)', () {
      final enKeys = LanguageService.getKeysForLanguage('en');
      expect(enKeys.length, greaterThanOrEqualTo(417));

      for (final lang in LanguageService.supportedLanguages) {
        final langKeys = LanguageService.getKeysForLanguage(lang.code);
        final missing = enKeys.difference(langKeys);
        final extra = langKeys.difference(enKeys);

        expect(
          missing,
          isEmpty,
          reason: 'Language "${lang.code}" is missing keys from English: $missing',
        );
        expect(
          extra,
          isEmpty,
          reason: 'Language "${lang.code}" has extra keys not in English: $extra',
        );
        expect(langKeys.length, enKeys.length);
      }
    });
  });
}
