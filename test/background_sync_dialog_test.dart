import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/services/cloud_sync_service.dart';
import 'package:balance_tracker/widgets/sync_conflict_dialog.dart';

void main() {
  testWidgets(
    'conflicting versions require review even with identical totals',
    (tester) async {
      const summary = VaultSummary(
        totalBalance: 10,
        transactionCount: 1,
        goalsCount: 0,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncConflictDialog(
              cloudSummary: summary,
              localSummary: summary,
              currency: 'USD',
              conflictCount: 1,
            ),
          ),
        ),
      );
      expect(
        find.textContaining('1 record(s) have unresolved versions'),
        findsOneWidget,
      );
      expect(find.textContaining('Settings.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
