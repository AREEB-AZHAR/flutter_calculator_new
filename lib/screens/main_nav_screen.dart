import 'package:flutter/material.dart';
import '../services/state.dart';
import '../services/language_service.dart';
import '../widgets/offline_banner.dart';
import 'dashboard_screen.dart';
import 'insights_screen.dart';
import 'goals_screen.dart';
import 'accounts_screen.dart';
import 'profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  @override
  void initState() {
    super.initState();
    AppState.activeTabNotifier.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    AppState.activeTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildActiveScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen(key: ValueKey('tab_dashboard'));
      case 1:
        return const InsightsScreen(key: ValueKey('tab_insights'));
      case 2:
        return const GoalsScreen(key: ValueKey('tab_goals'));
      case 3:
        return const AccountsScreen(key: ValueKey('tab_accounts'));
      case 4:
        return const ProfileScreen(key: ValueKey('tab_profile'));
      default:
        return const DashboardScreen(key: ValueKey('tab_dashboard'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppState.currentUser == null) {
      return const Scaffold();
    }

    final currentIndex = AppState.activeTabNotifier.value;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: _buildActiveScreen(currentIndex),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<String>(
        valueListenable: LanguageService.currentLanguageNotifier,
        builder: (context, lang, child) {
          return NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => AppState.activeTabNotifier.value = i,
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.dashboard), label: LanguageService.tr('nav_home')),
              NavigationDestination(icon: const Icon(Icons.insights), label: LanguageService.tr('nav_insights')),
              NavigationDestination(icon: const Icon(Icons.flag), label: LanguageService.tr('nav_goals')),
              NavigationDestination(icon: const Icon(Icons.account_balance_wallet), label: LanguageService.tr('nav_accounts')),
              NavigationDestination(icon: const Icon(Icons.person), label: LanguageService.tr('nav_profile')),
            ],
          );
        },
      ),
    );
  }
}
