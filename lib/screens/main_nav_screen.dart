import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/state.dart';
import '../services/language_service.dart';
import '../services/ad_service.dart';
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
  final Map<int, Widget> _cachedScreens = {};

  @override
  void initState() {
    super.initState();
    AppState.activeTabNotifier.addListener(_onTabChanged);
    _persistDeviceScreenCacheFlag();
  }

  Future<void> _persistDeviceScreenCacheFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tally_device_screen_cache_warmed', true);
    } catch (_) {}
  }

  @override
  void dispose() {
    AppState.activeTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildScreen(int index) {
    return _cachedScreens.putIfAbsent(index, () {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (AppState.currentUser == null) {
      return const Scaffold();
    }

    final currentIndex = AppState.activeTabNotifier.value;
    // Ensure current screen is initialized and cached
    _buildScreen(currentIndex);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: List.generate(5, (i) {
                  return RepaintBoundary(
                    child: TickerMode(
                      enabled: i == currentIndex,
                      child: _cachedScreens[i] ?? const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<String>(
        valueListenable: LanguageService.currentLanguageNotifier,
        builder: (context, lang, child) {
          // Bottom navigation bar stays strictly LTR (Home -> Profile) regardless of RTL language
          return Directionality(
            textDirection: TextDirection.ltr,
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) {
                if (i == currentIndex) return;
                // 1. Immediately switch tab so the target screen renders smoothly
                AppState.activeTabNotifier.value = i;
                // 2. Schedule interstitial ad check after the frame renders to eliminate frame drops & jank
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  AdService.showTabSwitchInterstitialAd(
                    context: context,
                    onComplete: () {},
                  );
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.dashboard), label: LanguageService.tr('nav_home')),
                NavigationDestination(icon: const Icon(Icons.insights), label: LanguageService.tr('nav_insights')),
                NavigationDestination(icon: const Icon(Icons.flag), label: LanguageService.tr('nav_goals')),
                NavigationDestination(icon: const Icon(Icons.account_balance_wallet), label: LanguageService.tr('nav_accounts')),
                NavigationDestination(icon: const Icon(Icons.person), label: LanguageService.tr('nav_profile')),
              ],
            ),
          );
        },
      ),
    );
  }
}
