import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/screens/main_nav_screen.dart';
import 'package:balance_tracker/screens/dashboard_screen.dart';
import 'package:balance_tracker/screens/goals_screen.dart';
import 'package:balance_tracker/widgets/cloud_sync_modal.dart';
import 'package:balance_tracker/services/cloud_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.database;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState.currentUser = 'TestUser';
    AppState.activeTabNotifier.value = 0;
  });

  group('MainNavScreen Background Pre-Build & Tab Caching Tests', () {
    testWidgets('MainNavScreen initializes with DashboardScreen and warms screen cache flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DashboardScreen), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tally_device_screen_cache_warmed'), isTrue);
    });

    testWidgets('Switching tabs mounts new screen into IndexedStack preserving cached screens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavScreen(),
        ),
      );

      await tester.pump();
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Switch to Goals (tab 2)
      AppState.activeTabNotifier.value = 2;
      await tester.pump();

      expect(find.byType(GoalsScreen), findsOneWidget);
      // DashboardScreen remains in IndexedStack tree (offstage), preserved in memory
      expect(find.byType(DashboardScreen, skipOffstage: false), findsOneWidget);
    });
  });

  group('CloudSyncModal Widget & Selection Flow Tests', () {
    testWidgets('CloudSyncModal displays comparing state initially when summaries need loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudSyncModal(
              username: 'TestUser',
              currency: '\$',
            ),
          ),
        ),
      );

      // Initial state is comparing
      expect(find.text('Comparing Cloud & Device Data'), findsOneWidget);
      expect(find.text('Retrieving your cloud records and checking device data...'), findsOneWidget);
    });

    testWidgets('CloudSyncModal renders clean comparison and all 3 plain-language choices', (tester) async {
      final localSummary = VaultSummary(
        totalBalance: 2450.50,
        transactionCount: 35,
        goalsCount: 2,
        lastModified: DateTime(2026, 10, 21),
      );
      final cloudSummary = VaultSummary(
        totalBalance: 2000.00,
        transactionCount: 30,
        goalsCount: 1,
        lastModified: DateTime(2026, 10, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CloudSyncModal(
              username: 'TestUser',
              currency: '\$',
              initialLocalSummary: localSummary,
              initialCloudSummary: cloudSummary,
            ),
          ),
        ),
      );

      await tester.pump();

      // Selection state rendered
      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.text('On Device'), findsOneWidget);
      expect(find.text('In Cloud'), findsOneWidget);

      // Balance comparison amounts
      expect(find.text('\$2450.50'), findsOneWidget);
      expect(find.text('\$2000.00'), findsOneWidget);

      // Verify all 3 sync action options are present with plain-language change descriptions
      expect(find.text('Mix & Merge Data'), findsOneWidget);
      expect(find.text('Load Saved Data'), findsOneWidget);
      expect(find.text('Upload Fresh Data'), findsOneWidget);

      // Verify plain language descriptions without technical jargon
      expect(find.textContaining('Combines both device and cloud records'), findsOneWidget);
      expect(find.textContaining('Replaces local records on this device with your cloud backup records'), findsOneWidget);
      expect(find.textContaining('Overwrites cloud backup with current device records as an exact copy'), findsOneWidget);
    });

    testWidgets('Tapping different sync action options updates active selection', (tester) async {
      final localSummary = VaultSummary(
        totalBalance: 1200.0,
        transactionCount: 15,
        goalsCount: 2,
        lastModified: DateTime(2026, 10, 21),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CloudSyncModal(
              username: 'TestUser',
              currency: '\$',
              initialLocalSummary: localSummary,
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap on Load Saved Data
      await tester.tap(find.text('Load Saved Data'));
      await tester.pump();

      // Tap on Upload Fresh Data
      await tester.tap(find.text('Upload Fresh Data'));
      await tester.pump();

      // Button to proceed is present
      expect(find.text('Proceed with Sync'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
