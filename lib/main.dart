import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/in_app_purchase_service.dart';
import 'services/ad_service.dart';
import 'services/monetization_service.dart';
import 'services/state.dart';
import 'utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize desktop SQLite FFI for Windows/Linux debug & release modes
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize notifications & schedule reminders
  await NotificationService.instance.init();

  // Initialize monetization and pro/ad-free purchase state
  await MonetizationService.initialize();

  // Initialize official Google Play In-App Purchase service
  await InAppPurchaseService.instance.initialize();

  // Initialize Google Mobile Ads SDK on supported platforms and preload rewarded ads
  await AdService.initialize();

  // Load saved theme settings so SplashScreen and LoginScreen immediately boot with the user's chosen theme
  await AppState.initGlobalTheme();

  // Load and initialize Firebase if configured
  await DefaultFirebaseOptions.loadSavedConfig();
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  runApp(const TallyApp());
}

class TallyApp extends StatelessWidget {
  const TallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppState.themeNameNotifier,
        AppState.customPrimaryColorNotifier,
        AppState.customSecondaryColorNotifier,
        AppState.customTextColorNotifier,
      ]),
      builder: (context, _) {
        final themeName = AppState.themeNameNotifier.value;
        final primaryColor = AppState.customPrimaryColorNotifier.value;
        final secondaryColor = AppState.customSecondaryColorNotifier.value;
        final textColor = AppState.customTextColorNotifier.value;

        return MaterialApp(
          title: 'Tally',
          theme: buildDynamicTheme(
            primary: primaryColor,
            secondary: secondaryColor,
            textColor: textColor,
            themeName: themeName,
          ),
          themeAnimationDuration: const Duration(milliseconds: 150),
          themeAnimationCurve: Curves.easeInOut,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
