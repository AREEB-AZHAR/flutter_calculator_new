import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/state.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize desktop SQLite FFI for Windows/Linux debug & release modes
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize notifications & schedule reminders
  await NotificationService.instance.init();

  runApp(const TallyApp());
}

class TallyApp extends StatelessWidget {
  const TallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.themeNameNotifier,
      builder: (context, themeName, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: AppState.customPrimaryColorNotifier,
          builder: (context, primaryColor, _) {
            return ValueListenableBuilder<Color>(
              valueListenable: AppState.customSecondaryColorNotifier,
              builder: (context, secondaryColor, _) {
                return ValueListenableBuilder<Color?>(
                  valueListenable: AppState.customTextColorNotifier,
                  builder: (context, textColor, _) {
                    return MaterialApp(
                      title: 'Tally',
                      theme: buildDynamicTheme(
                        primary: primaryColor,
                        secondary: secondaryColor,
                        textColor: textColor,
                        themeName: themeName,
                      ),
                      home: const SplashScreen(),
                      debugShowCheckedModeBanner: false,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
