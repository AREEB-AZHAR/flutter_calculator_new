import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/services/language_service.dart';
import 'package:balance_tracker/services/connectivity_service.dart';
import 'package:balance_tracker/services/cloud_sync_service.dart';
import 'package:balance_tracker/widgets/sync_conflict_dialog.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('LanguageService Tests', () {
    test('Supports all 7 international languages with correct RTL flag', () {
      expect(LanguageService.supportedLanguages.length, 7);
      
      final urdu = LanguageService.supportedLanguages.firstWhere((l) => l.code == 'ur');
      expect(urdu.isRtl, isTrue);

      final arabic = LanguageService.supportedLanguages.firstWhere((l) => l.code == 'ar');
      expect(arabic.isRtl, isTrue);

      final english = LanguageService.supportedLanguages.firstWhere((l) => l.code == 'en');
      expect(english.isRtl, isFalse);

      final spanish = LanguageService.supportedLanguages.firstWhere((l) => l.code == 'es');
      expect(spanish.isRtl, isFalse);
    });

    test('Translates keys accurately across languages and falls back gracefully', () async {
      // English
      await LanguageService.setLanguage('en');
      expect(LanguageService.isRtl, isFalse);
      expect(LanguageService.tr('save'), 'Save');
      expect(LanguageService.tr('cancel'), 'Cancel');

      // Spanish
      await LanguageService.setLanguage('es');
      expect(LanguageService.isRtl, isFalse);
      expect(LanguageService.tr('save'), 'Guardar');
      expect(LanguageService.tr('cancel'), 'Cancelar');

      // Urdu (RTL)
      await LanguageService.setLanguage('ur');
      expect(LanguageService.isRtl, isTrue);
      expect(LanguageService.tr('save'), 'محفوظ کریں');
      expect(LanguageService.tr('cancel'), 'منسوخ کریں');

      // Arabic (RTL)
      await LanguageService.setLanguage('ar');
      expect(LanguageService.isRtl, isTrue);
      expect(LanguageService.tr('save'), 'حفظ');
      expect(LanguageService.tr('cancel'), 'إلغاء');

      // Hindi
      await LanguageService.setLanguage('hi');
      expect(LanguageService.isRtl, isFalse);
      expect(LanguageService.tr('save'), 'सहेजें');
      expect(LanguageService.tr('cancel'), 'रद्द करें');

      // French
      await LanguageService.setLanguage('fr');
      expect(LanguageService.tr('save'), 'Enregistrer');

      // German
      await LanguageService.setLanguage('de');
      expect(LanguageService.tr('save'), 'Speichern');

      // Reset to EN
      await LanguageService.setLanguage('en');
      expect(LanguageService.currentLanguageNotifier.value, 'en');
    });
  });

  group('ConnectivityService Tests', () {
    test('Exposes reactive online state notifier', () {
      expect(ConnectivityService.isOnlineNotifier.value, isNotNull);
      final initial = ConnectivityService.isOnline;
      expect(initial, isA<bool>());
    });
  });

  group('VaultSummary & Conflict Choice Tests', () {
    test('VaultSummary encapsulates balance and counts properly', () {
      final summary = VaultSummary(
        totalBalance: 4250.75,
        transactionCount: 15,
        goalsCount: 3,
        lastModified: DateTime(2026, 10, 2),
      );

      expect(summary.totalBalance, 4250.75);
      expect(summary.transactionCount, 15);
      expect(summary.goalsCount, 3);
      expect(summary.lastModified?.year, 2026);
    });

    test('SyncConflictChoice covers all 3 decision paths', () {
      expect(SyncConflictChoice.values, contains(SyncConflictChoice.restoreCloud));
      expect(SyncConflictChoice.values, contains(SyncConflictChoice.overwriteCloud));
      expect(SyncConflictChoice.values, contains(SyncConflictChoice.offlineOnly));
    });
  });
}
