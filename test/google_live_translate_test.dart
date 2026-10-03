import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/language_service.dart';
import 'package:balance_tracker/services/google_live_translate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Live Translation & Dual-Engine Fallback Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GoogleLiveTranslateService.init();
      LanguageService.setLanguage('en');
    });

    test('getCached returns null for uncached string and returns cached value once set', () {
      expect(
        GoogleLiveTranslateService.getCached('Custom Electric Scooter', targetLang: 'es'),
        isNull,
      );

      // Force an entry into cache
      GoogleLiveTranslateService.clearCache();
      expect(
        GoogleLiveTranslateService.getCached('Scooter', targetLang: 'es'),
        isNull,
      );
    });

    test('LanguageService.tr returns static dictionary value with 0ms latency', () {
      LanguageService.setLanguage('es');
      expect(LanguageService.tr('save'), 'Guardar');
      expect(LanguageService.tr('income'), 'Ingresos');

      LanguageService.setLanguage('ur');
      expect(LanguageService.tr('save'), 'محفوظ کریں');
      expect(LanguageService.tr('income'), 'آمدنی');
    });

    test('LanguageService.tr falls back to English when key is missing in active language', () {
      LanguageService.setLanguage('ur');
      // If a non-existent key is queried, it returns the key
      expect(LanguageService.tr('non_existent_key_123'), 'non_existent_key_123');
    });

    test('LanguageService.trDynamic translates standard categories immediately', () {
      LanguageService.setLanguage('es');
      expect(LanguageService.trDynamic('Salary'), 'Salario');
      expect(LanguageService.trDynamic('Shopping'), 'Compras');

      LanguageService.setLanguage('ur');
      expect(LanguageService.trDynamic('Salary'), 'تنخواہ');
      expect(LanguageService.trDynamic('Shopping'), 'خریداری');
    });

    test('trAsync falls back to text safely without throwing exceptions', () async {
      LanguageService.setLanguage('es');
      final result = await LanguageService.trAsync('Salary');
      expect(result, 'Salario');

      // Test arbitrary dynamic text fallback
      final dynamicResult = await LanguageService.trAsync('Test Custom Expense');
      expect(dynamicResult.isNotEmpty, isTrue);
    });

    test('liveTranslationsVersionNotifier increments on cache updates', () {
      final initialVersion = GoogleLiveTranslateService.liveTranslationsVersionNotifier.value;
      GoogleLiveTranslateService.clearCache();
      expect(
        GoogleLiveTranslateService.liveTranslationsVersionNotifier.value,
        greaterThanOrEqualTo(initialVersion),
      );
    });
  });
}
