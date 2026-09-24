import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/models/transaction.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/services/biometric_service.dart';
import 'package:balance_tracker/services/tour_service.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/google_auth_service.dart';
import 'package:balance_tracker/widgets/ad_banner_widget.dart';
import 'package:balance_tracker/screens/insights_screen.dart';
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

  test('TourService tracks tour completion and resets correctly', () async {
    expect(await TourService.isTourCompleted(TourService.tourHome), false);
    expect(await TourService.isTourCompleted(TourService.tourAccounts), false);

    await TourService.markTourCompleted(TourService.tourHome);
    expect(await TourService.isTourCompleted(TourService.tourHome), true);
    expect(await TourService.isTourCompleted(TourService.tourAccounts), false);

    await TourService.markTourCompleted(TourService.tourAccounts);
    expect(await TourService.isTourCompleted(TourService.tourAccounts), true);

    await TourService.resetAllTours();
    expect(await TourService.isTourCompleted(TourService.tourHome), false);
    expect(await TourService.isTourCompleted(TourService.tourAccounts), false);
  });

  test('BiometricService session prompt resets on logout', () {
    BiometricService.biometricPromptCheckedThisSession = true;
    expect(BiometricService.biometricPromptCheckedThisSession, true);

    BiometricService.resetSessionPrompt();
    expect(BiometricService.biometricPromptCheckedThisSession, false);
  });

  testWidgets('Transaction Dialog: Selecting Income auto-switches category to Salary & auto-fills title', (WidgetTester tester) async {
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

    // Verify initial category is Food & Dining and Expense is active
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    // Tap Income
    await tester.ensureVisible(find.text('Income'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    // Enter amount without entering any title
    final amountFinder = find.byType(TextField).at(1);
    await tester.enterText(amountFinder, '4500');

    // Tap Add
    await tester.ensureVisible(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(AppState.transactionsNotifier.value.length, 1);
    final tx = AppState.transactionsNotifier.value.first;
    expect(tx.isIncome, true);
    expect(tx.category, 'Salary');
    expect(tx.title, 'Salary'); // Auto-filled from category!
    expect(tx.amount, 4500.0);
  });

  test('MonetizationService: tier transitions, separate remove-ads, and promo codes', () async {
    await MonetizationService.resetPurchases();
    expect(MonetizationService.isPro, false);
    expect(MonetizationService.isAdFree, false);

    // Test separate Remove Ads purchase
    await MonetizationService.removeAds();
    expect(MonetizationService.isPro, false);
    expect(MonetizationService.isAdFree, true);

    // Test reset
    await MonetizationService.resetPurchases();
    expect(MonetizationService.isPro, false);
    expect(MonetizationService.isAdFree, false);

    // Test unlock Pro (gives both Pro and Ad-Free)
    await MonetizationService.unlockPro();
    expect(MonetizationService.isPro, true);
    expect(MonetizationService.isAdFree, true);

    // Test Promo Code NOADS
    await MonetizationService.resetPurchases();
    final noAdsResult = await MonetizationService.redeemPromoCode('NOADS');
    expect(noAdsResult, isNotNull);
    expect(MonetizationService.isPro, false);
    expect(MonetizationService.isAdFree, true);

    // Test Promo Code PROVIP
    await MonetizationService.resetPurchases();
    final proResult = await MonetizationService.redeemPromoCode('PROVIP');
    expect(proResult, isNotNull);
    expect(MonetizationService.isPro, true);
    expect(MonetizationService.isAdFree, true);

    // Test Invalid Promo Code
    final invalidResult = await MonetizationService.redeemPromoCode('INVALID_CODE');
    expect(invalidResult, isNull);

    await MonetizationService.resetPurchases();
  });

  test('GoogleAuthService: detects Google email bindings', () {
    AppState.currentUser = 'user123';
    expect(GoogleAuthService.isCurrentGoogleUser, false);

    AppState.currentUser = 'areeb.finance@gmail.com';
    expect(GoogleAuthService.isCurrentGoogleUser, true);

    AppState.currentUser = null;
    expect(GoogleAuthService.isCurrentGoogleUser, false);
  });

  testWidgets('AdBannerWidget: displays banner for free users and hides when ad-free or pro', (WidgetTester tester) async {
    await MonetizationService.resetPurchases();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdBannerWidget(
            sponsorCategory: 'Test Fintech Partner',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Banner should be visible with "Ad" badge and sponsor text
    expect(find.text('Ad'), findsOneWidget);
    expect(find.text('Test Fintech Partner'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);

    // Unlock separate Remove Ads
    await MonetizationService.removeAds();
    await tester.pumpAndSettle();

    // Banner should be completely hidden
    expect(find.text('Ad'), findsNothing);
    expect(find.text('Test Fintech Partner'), findsNothing);

    await MonetizationService.resetPurchases();
  });

  testWidgets('InsightsScreen: Free users see Tally Pro lock screen, Pro users see insights', (WidgetTester tester) async {
    await MonetizationService.resetPurchases();

    await tester.pumpWidget(
      const MaterialApp(
        home: InsightsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Free user should see Pro lock screen
    expect(find.text('TALLY PRO EXCLUSIVE'), findsOneWidget);
    expect(find.text('Smart Financial Intelligence'), findsOneWidget);
    expect(find.text('Unlock Tally Pro — \$4.99'), findsOneWidget);
    expect(find.text('Have an unlock code? Redeem Promo'), findsOneWidget);

    // Unlock Pro
    await MonetizationService.unlockPro();
    await tester.pumpAndSettle();

    // Pro user should see real insights screen (or empty prompt if no transactions)
    expect(find.text('TALLY PRO EXCLUSIVE'), findsNothing);
    expect(find.text('Add some transactions to see insights!'), findsOneWidget);

    await MonetizationService.resetPurchases();
  });
}
