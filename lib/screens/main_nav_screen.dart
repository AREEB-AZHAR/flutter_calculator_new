import 'package:flutter/material.dart';
import '../services/state.dart';
import 'dashboard_screen.dart';
import 'insights_screen.dart';
import 'goals_screen.dart';
import 'accounts_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    InsightsScreen(),
    GoalsScreen(),
    AccountsScreen(),
    ProfileScreen(),
  ];

  final Set<int> _loadedTabs = {0};

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
    if (mounted) {
      final current = AppState.activeTabNotifier.value;
      if (!_loadedTabs.contains(current)) {
        _loadedTabs.add(current);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppState.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      });
      return const Scaffold();
    }

    final currentIndex = AppState.activeTabNotifier.value;
    if (!_loadedTabs.contains(currentIndex)) {
      _loadedTabs.add(currentIndex);
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: List.generate(_screens.length, (index) {
          if (_loadedTabs.contains(index)) {
            return _screens[index];
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => AppState.activeTabNotifier.value = i,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
