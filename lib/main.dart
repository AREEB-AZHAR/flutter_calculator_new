import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/splash_screen.dart';
import 'services/state.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize desktop SQLite FFI for Windows/Linux debug & release modes
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const BalanceTrackerApp());
}

class BalanceTrackerApp extends StatelessWidget {
  const BalanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppState.customPrimaryColorNotifier,
      builder: (context, primaryColor, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: AppState.customSecondaryColorNotifier,
          builder: (context, secondaryColor, _) {
            return MaterialApp(
              title: 'Tally',
              theme: buildDynamicTheme(primary: primaryColor, secondary: secondaryColor),
              home: const SplashScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
