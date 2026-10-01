import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language descriptor model.
class LanguageOption {
  final String code;
  final String englishName;
  final String nativeName;
  final bool isRtl;

  const LanguageOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
    this.isRtl = false,
  });
}

/// Global Localization & Multi-Language Engine for Tally.
class LanguageService {
  LanguageService._();

  static const String _prefLanguageKey = 'tally_selected_language';

  /// Supported languages across international locales.
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', englishName: 'English', nativeName: 'English'),
    LanguageOption(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
    LanguageOption(code: 'fr', englishName: 'French', nativeName: 'Français'),
    LanguageOption(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
    LanguageOption(code: 'ur', englishName: 'Urdu', nativeName: 'اردو', isRtl: true),
    LanguageOption(code: 'ar', englishName: 'Arabic', nativeName: 'العربية', isRtl: true),
    LanguageOption(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
  ];

  /// Reactive notifier for the currently selected language code.
  static final ValueNotifier<String> currentLanguageNotifier = ValueNotifier<String>('en');

  /// Indicates if the active language is right-to-left (RTL).
  static bool get isRtl {
    final lang = currentLanguageNotifier.value;
    return lang == 'ur' || lang == 'ar';
  }

  /// Initializes the saved language from persistent storage.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefLanguageKey);
      if (savedLang != null && supportedLanguages.any((l) => l.code == savedLang)) {
        currentLanguageNotifier.value = savedLang;
      }
    } catch (e) {
      debugPrint('LanguageService.init notice: $e');
    }
  }

  /// Updates and persists the current language.
  static Future<void> setLanguage(String code) async {
    if (!supportedLanguages.any((l) => l.code == code)) return;
    currentLanguageNotifier.value = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, code);
    } catch (e) {
      debugPrint('LanguageService.setLanguage notice: $e');
    }
  }

  /// Translates a given key with fallback to English, then to the key itself.
  static String tr(String key) {
    final lang = currentLanguageNotifier.value;
    final dict = _translations[lang];
    if (dict != null && dict.containsKey(key)) {
      return dict[key]!;
    }
    // Fallback to English
    final enDict = _translations['en'];
    if (enDict != null && enDict.containsKey(key)) {
      return enDict[key]!;
    }
    return key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Tally',
      'home': 'Home',
      'insights': 'Insights',
      'goals': 'Goals',
      'accounts': 'Accounts',
      'profile': 'Profile',
      'balance': 'Balance',
      'income': 'Income',
      'expense': 'Expense',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'settings': 'Settings',
      'currency': 'Currency',
      'language': 'Language',
      'notifications': 'Notifications',
      'offline_warning': 'You are offline. Your changes are saved locally and will sync when reconnected.',
      'offline_google_title': 'Internet Connection Required',
      'offline_google_desc': 'Google Sign-In requires an active internet connection. You can create or use a local account right now, and all your records will automatically sync with Google Cloud when you connect to the internet.',
      'use_local_account': 'Continue with Local Account',
      'sync_conflict_title': 'Sync Conflict Detected',
      'sync_conflict_desc': 'We found existing cloud records and newer local records. Please choose how you would like to proceed.',
      'cloud_data': 'Google Cloud Vault',
      'local_data': 'On-Device Storage',
      'restore_cloud': 'Restore from Cloud',
      'upload_local': 'Upload Device Data',
      'continue_offline': 'Keep Using Offline Only',
      'offline_data_loss_warning': '⚠️ Notice: Data will only remain on this device. If you uninstall the app or clear device storage, data will be lost.',
    },
    'es': {
      'app_title': 'Tally',
      'home': 'Inicio',
      'insights': 'Estadísticas',
      'goals': 'Metas',
      'accounts': 'Cuentas',
      'profile': 'Perfil',
      'balance': 'Saldo',
      'income': 'Ingresos',
      'expense': 'Gastos',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'settings': 'Ajustes',
      'currency': 'Moneda',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'offline_warning': 'Estás desconectado. Los cambios se guardan localmente y se sincronizarán al reconectar.',
      'offline_google_title': 'Conexión a Internet Requerida',
      'offline_google_desc': 'El inicio de sesión de Google requiere conexión a internet. Puedes crear o usar una cuenta local ahora, y tus datos se sincronizarán con la nube al reconectarte.',
      'use_local_account': 'Continuar con Cuenta Local',
      'sync_conflict_title': 'Conflicto de Sincronización Detectado',
      'sync_conflict_desc': 'Encontramos datos en la nube y registros locales más recientes. Elige cómo deseas proceder.',
      'cloud_data': 'Bóveda en la Nube',
      'local_data': 'Almacenamiento Local',
      'restore_cloud': 'Restaurar de la Nube',
      'upload_local': 'Subir Datos Locales',
      'continue_offline': 'Continuar Solo Local',
      'offline_data_loss_warning': '⚠️ Aviso: Los datos solo permanecerán en este dispositivo. Si desinstalas la app o borras la caché, los datos se perderán.',
    },
    'fr': {
      'app_title': 'Tally',
      'home': 'Accueil',
      'insights': 'Aperçus',
      'goals': 'Objectifs',
      'accounts': 'Comptes',
      'profile': 'Profil',
      'balance': 'Solde',
      'income': 'Revenus',
      'expense': 'Dépenses',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'settings': 'Paramètres',
      'currency': 'Devise',
      'language': 'Langue',
      'notifications': 'Notifications',
      'offline_warning': 'Vous êtes hors ligne. Vos modifications sont enregistrées localement et seront synchronisées à la reconnexion.',
      'offline_google_title': 'Connexion Internet Requise',
      'offline_google_desc': 'La connexion Google nécessite internet. Vous pouvez créer ou utiliser un compte local maintenant, et vos données se synchroniseront automatiquement.',
      'use_local_account': 'Continuer avec un Compte Local',
      'sync_conflict_title': 'Conflit de Synchronisation',
      'sync_conflict_desc': 'Nous avons détecté des données dans le cloud et des données locales plus récentes. Veuillez choisir comment procéder.',
      'cloud_data': 'Coffre Cloud Google',
      'local_data': 'Stockage sur l\'appareil',
      'restore_cloud': 'Restaurer depuis le Cloud',
      'upload_local': 'Téléverser Données Locales',
      'continue_offline': 'Garder Hors Ligne Uniquement',
      'offline_data_loss_warning': '⚠️ Avertissement : Les données resteront uniquement sur cet appareil. Si vous désinstallez l\'application, les données seront perdues.',
    },
    'de': {
      'app_title': 'Tally',
      'home': 'Start',
      'insights': 'Einblicke',
      'goals': 'Ziele',
      'accounts': 'Konten',
      'profile': 'Profil',
      'balance': 'Kontostand',
      'income': 'Einnahmen',
      'expense': 'Ausgaben',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'settings': 'Einstellungen',
      'currency': 'Währung',
      'language': 'Sprache',
      'notifications': 'Benachrichtigungen',
      'offline_warning': 'Sie sind offline. Änderungen werden lokal gespeichert und bei Wiederverbindung synchronisiert.',
      'offline_google_title': 'Internetverbindung erforderlich',
      'offline_google_desc': 'Google-Login erfordert eine aktive Verbindung. Sie können ein lokales Konto verwenden; Daten werden später synchronisiert.',
      'use_local_account': 'Mit lokalem Konto fortfahren',
      'sync_conflict_title': 'Synchronisationskonflikt',
      'sync_conflict_desc': 'Cloud-Daten und neuere lokale Daten wurden gefunden. Bitte wählen Sie, wie fortgefahren werden soll.',
      'cloud_data': 'Google Cloud-Tresor',
      'local_data': 'Lokaler Speicher',
      'restore_cloud': 'Aus Cloud wiederherstellen',
      'upload_local': 'Lokale Daten hochladen',
      'continue_offline': 'Nur offline fortfahren',
      'offline_data_loss_warning': '⚠️ Warnung: Daten verbleiben nur auf diesem Gerät. Bei Deinstallation der App gehen die Daten verloren.',
    },
    'ur': {
      'app_title': 'ٹیلی',
      'home': 'ہوم',
      'insights': 'تجزیات',
      'goals': 'اہداف',
      'accounts': 'اکاؤنٹس',
      'profile': 'پروفائل',
      'balance': 'بیلنس',
      'income': 'آمدنی',
      'expense': 'اخراجات',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ کریں',
      'delete': 'حذف کریں',
      'edit': 'ترمیم کریں',
      'settings': 'ترتیبات',
      'currency': 'کرنسی',
      'language': 'زبان',
      'notifications': 'نوٹیفیکیشنز',
      'offline_warning': 'آپ آف لائن ہیں۔ تبدیلیاں مقامی طور پر محفوظ ہیں اور دوبارہ رابطہ ہونے پر خودکار مطابقت پذیر ہو جائیں گی۔',
      'offline_google_title': 'انٹرنیٹ کنکشن درکار ہے',
      'offline_google_desc': 'گوگل سائن ان کے لیے انٹرنیٹ ضروری ہے۔ آپ ابھی مقامی اکاؤنٹ بنا سکتے ہیں جو بعد میں گوگل کلاؤڈ کے ساتھ مطابقت پذیر ہو جائے گا۔',
      'use_local_account': 'مقامی اکاؤنٹ کے ساتھ جاری رکھیں',
      'sync_conflict_title': 'مطابقت پذیری کا تنازع',
      'sync_conflict_desc': 'کلاؤڈ اور مقامی ڈیٹا دونوں موجود ہیں۔ براہ کرم منتخب کریں کہ آپ کیسے آگے بڑھنا چاہتے ہیں۔',
      'cloud_data': 'گوگل کلاؤڈ ڈیٹا',
      'local_data': 'مقامی ڈیوائس ڈیٹا',
      'restore_cloud': 'کلاؤڈ سے بحال کریں',
      'upload_local': 'مقامی ڈیٹا اپ لوڈ کریں',
      'continue_offline': 'صرف آف لائن جاری رکھیں',
      'offline_data_loss_warning': '⚠️ انتباہ: ڈیٹا صرف اس ڈیوائس پر رہے گا۔ اگر آپ ایپ ان انسٹال کرتے ہیں تو ڈیٹا ضائع ہو جائے گا۔',
    },
    'ar': {
      'app_title': 'تالی',
      'home': 'الرئيسية',
      'insights': 'التحليلات',
      'goals': 'الأهداف',
      'accounts': 'الحسابات',
      'profile': 'الملف الشخصي',
      'balance': 'الرصيد',
      'income': 'الدخل',
      'expense': 'المصروفات',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'settings': 'الإعدادات',
      'currency': 'العملة',
      'language': 'اللغة',
      'notifications': 'الإشعارات',
      'offline_warning': 'أنت غير متصل بالإنترنت. تم حفظ تغييراتك محليًا وستتم مزامنتها عند إعادة الاتصال.',
      'offline_google_title': 'الاتصال بالإنترنت مطلوب',
      'offline_google_desc': 'يتطلب تسجيل الدخول عبر Google اتصالاً نشطًا. يمكنك إنشاء حساب محلي الآن وستتم مزامنته لاحقًا.',
      'use_local_account': 'المتابعة بحساب محلي',
      'sync_conflict_title': 'تم اكتشاف تعارض في المزامنة',
      'sync_conflict_desc': 'تم العثور على بيانات سحابية وبيانات محلية أحدث. يرجى اختيار كيفية المتابعة.',
      'cloud_data': 'بيانات Google Cloud',
      'local_data': 'التخزين المحلي بالجهاز',
      'restore_cloud': 'استعادة من السحابة',
      'upload_local': 'رفع البيانات المحلية',
      'continue_offline': 'المتابعة دون اتصال فقط',
      'offline_data_loss_warning': '⚠️ تحذير: ستبقى البيانات على هذا الجهاز فقط. في حال إلغاء تثبيت التطبيق، سيتم فقد البيانات.',
    },
    'hi': {
      'app_title': 'टैली',
      'home': 'होम',
      'insights': 'विश्लेषण',
      'goals': 'लक्ष्य',
      'accounts': 'खाते',
      'profile': 'प्रोफ़ाइल',
      'balance': 'बैलेंस',
      'income': 'आय',
      'expense': 'खर्च',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'settings': 'सेटिंग्स',
      'currency': 'मुद्रा',
      'language': 'भाषा',
      'notifications': 'सूचनाएं',
      'offline_warning': 'आप ऑफ़लाइन हैं। आपके परिवर्तन स्थानीय रूप से सहेजे गए हैं और पुनः कनेक्ट होने पर सिंक हो जाएंगे।',
      'offline_google_title': 'इंटरनेट कनेक्शन आवश्यक',
      'offline_google_desc': 'Google लॉगिन के लिए सक्रिय इंटरनेट की आवश्यकता है। आप अभी एक स्थानीय खाता बना सकते हैं, जो इंटरनेट जुड़ने पर सिंक हो जाएगा।',
      'use_local_account': 'स्थानीय खाते के साथ जारी रखें',
      'sync_conflict_title': 'सिंक टकराव का पता चला',
      'sync_conflict_desc': 'क्लाउड रिकॉर्ड और नए स्थानीय रिकॉर्ड मिले हैं। कृपया चुनें कि आप कैसे आगे बढ़ना चाहते हैं।',
      'cloud_data': 'Google क्लाउड डेटा',
      'local_data': 'डिवाइस स्थानीय डेटा',
      'restore_cloud': 'क्लाउड से पुनर्स्थापित करें',
      'upload_local': 'स्थानीय डेटा अपलोड करें',
      'continue_offline': 'केवल ऑफ़लाइन जारी रखें',
      'offline_data_loss_warning': '⚠️ चेतावनी: डेटा केवल इस डिवाइस पर रहेगा। ऐप अनइंस्टॉल करने पर डेटा नष्ट हो जाएगा।',
    },
  };
}
