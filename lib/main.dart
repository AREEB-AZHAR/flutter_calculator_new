import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/state.dart';
import 'utils/constants.dart';

void main() {
  runApp(const BalanceTrackerApp());
}

class BalanceTrackerApp extends StatelessWidget {
  const BalanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.themeNameNotifier,
      builder: (context, themeName, _) {
        return MaterialApp(
          title: 'Balance Tracker',
          theme: buildAppTheme(themeName),
          home: const LoginScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
