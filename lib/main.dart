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
    return ValueListenableBuilder<Color>(
      valueListenable: AppState.customPrimaryColorNotifier,
      builder: (context, primaryColor, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: AppState.customSecondaryColorNotifier,
          builder: (context, secondaryColor, _) {
            return MaterialApp(
              title: 'Balance Tracker',
              theme: buildDynamicTheme(primary: primaryColor, secondary: secondaryColor),
              home: const LoginScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
