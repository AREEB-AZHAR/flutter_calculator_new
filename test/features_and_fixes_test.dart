import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/biometric_service.dart';
import 'package:balance_tracker/widgets/transaction_dialog.dart';
import 'package:balance_tracker/widgets/transaction_tile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppState.currencyNotifier.value = '\$';
    AppState.transactionsNotifier.value = [];
  });

  test('BiometricService toggles enabled state and persists associated username', () async {
    expect(await BiometricService.isBiometricEnabled(), false);
    expect(await BiometricService.getSavedBiometricUser(), null);

    await BiometricService.setBiometricEnabled(true, username: 'alice');
    expect(await BiometricService.isBiometricEnabled(), true);
    expect(await BiometricService.getSavedBiometricUser(), 'alice');

    await BiometricService.setBiometricEnabled(false);
    expect(await BiometricService.isBiometricEnabled(), false);
    expect(await BiometricService.getSavedBiometricUser(), null);
  });

  test('Currency updates reactively and persists without app relaunch', () async {
    expect(AppState.currencyNotifier.value, '\$');

    await AppState.setCurrency('€');
    expect(AppState.currencyNotifier.value, '€');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tally_currency_symbol'), '€');

    // Simulate app reboot initialization
    AppState.currencyNotifier.value = '\$'; // reset in-memory
    await AppState.initGlobalTheme();
    expect(AppState.currencyNotifier.value, '€');
  });

  testWidgets('TransactionTile updates currency dynamically without reload', (WidgetTester tester) async {
    final tx = Transaction(
      id: 'tx_1',
      title: 'Groceries',
      amount: 45.0,
      date: DateTime.now(),
      isIncome: false,
      category: 'Food & Dining',
      account: 'Main',
      recurrence: 'None',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionTile(
            tx: tx,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('-45'), findsNothing);
    expect(find.text('-\$45'), findsOneWidget);

    // Change currency live
    await AppState.setCurrency('₨');
    await tester.pump();

    expect(find.text('-₨45'), findsOneWidget);
  });

  testWidgets('Transaction Dialog: Empty title defaults to selected category name', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showTransactionDialog(context),
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Open transaction dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Leave title empty and enter amount
    final amountFinder = find.byType(TextField).at(1);
    await tester.enterText(amountFinder, '60');

    // Tap Add button
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify transaction was added with Category name as the title
    expect(AppState.transactionsNotifier.value.length, 1);
    final addedTx = AppState.transactionsNotifier.value.first;
    expect(addedTx.title, 'Food & Dining');
    expect(addedTx.amount, 60.0);
  });

  testWidgets('Transaction Dialog: Allows selecting custom transaction date and orders descending', (WidgetTester tester) async {
    // Existing transaction today
    AppState.transactionsNotifier.value = [
      Transaction(
        id: 'tx_today',
        title: 'Lunch',
        amount: 25.0,
        date: DateTime(2026, 9, 24),
        isIncome: false,
        category: 'Food & Dining',
        account: 'Main',
        recurrence: 'None',
      )
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showTransactionDialog(context),
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Enter title & amount
    await tester.enterText(find.byType(TextField).at(0), 'Past Conference');
    await tester.enterText(find.byType(TextField).at(1), '200');

    // Tap date picker container
    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();

    // Tap date 15 in the DatePickerDialog
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tap Add
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(AppState.transactionsNotifier.value.length, 2);
    // Verify list is sorted descending by date
    expect(AppState.transactionsNotifier.value[0].title, 'Lunch');
    expect(AppState.transactionsNotifier.value[1].title, 'Past Conference');
  });
}
