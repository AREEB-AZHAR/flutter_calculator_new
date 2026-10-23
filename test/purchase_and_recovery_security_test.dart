import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/services/purchase_backend.dart';
import 'package:balance_tracker/services/in_app_purchase_service.dart';
import 'package:balance_tracker/services/monetization_service.dart';
import 'package:balance_tracker/services/password_recovery_service.dart';
import 'package:balance_tracker/services/database/app_database.dart';
import 'package:balance_tracker/services/state.dart';
import 'package:balance_tracker/screens/premium_screen.dart';
import 'package:balance_tracker/widgets/password_recovery_dialog.dart';

class FakePurchaseBackend implements PurchaseBackend {
  late Future<Map<String, dynamic>> Function() work;
  @override
  Future<Map<String, dynamic>> verify(String productId, String token) => work();
  @override
  Future<Map<String, dynamic>> refresh() => work();
}

class FakeRecoveryBackend implements RecoveryBackend {
  static const id = '11111111-2222-3333-4444-555555555555';
  int verifications = 0;
  String? sentEmail;
  Future<Map<String, dynamic>> Function()? onBegin;
  Future<Map<String, dynamic>> Function()? onVerify;
  @override
  Future<Map<String, dynamic>> begin(String email) async {
    sentEmail = email;
    return onBegin == null
        ? {
            'challengeId': id,
            'expiresAtMs': DateTime.now()
                .add(const Duration(minutes: 10))
                .millisecondsSinceEpoch,
          }
        : await onBegin!();
  }

  @override
  Future<Map<String, dynamic>> verify(String challengeId, String code) async {
    verifications++;
    return onVerify == null
        ? {'verified': true, 'email': sentEmail, 'challengeId': challengeId}
        : await onVerify!();
  }
}

class DeliveryFailureRecoveryService extends PasswordRecoveryService {
  @override
  Future<void> begin(String email) async {
    throw StateError('Email delivery unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 23, 12);
  Map<String, dynamic> lease() => {
    'schema': 2,
    'uid': 'alice',
    'issuedAtMs': now.millisecondsSinceEpoch,
    'leaseExpiresAtMs': now
        .add(const Duration(minutes: 15))
        .millisecondsSinceEpoch,
    'pro_unlocked': true,
    'ads_removed': false,
    'trial_expiry': null,
  };
  Map<String, dynamic> verified() => {
    'verified': true,
    'active': true,
    'productId': 'tally_pro_lifetime',
    'tokenHash': sha256.convert(utf8.encode('receipt')).toString(),
    'entitlements': lease(),
  };
  setUp(() async {
    SharedPreferences.setMockInitialValues({'legacy_prefs_migrated': true});
    PurchaseSecurityPolicy.developmentOverride = false;
    MonetizationService.resetToLoggedOut();
    AppState.currentUser = null;
  });
  tearDown(() {
    MonetizationService.resetToLoggedOut();
    PurchaseSecurityPolicy.developmentOverride = null;
    AppState.currentUser = null;
  });

  group('Production purchase policy', () {
    test(
      'arguments and stored sandbox flag cannot grant production access',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tally_iap_tester_sandbox', true);
        final iap = InAppPurchaseService.instance;
        iap.isStoreAvailableNotifier.value = false;
        iap.isTesterSandboxNotifier.value = true;
        expect(
          await iap.buyProduct(
            InAppPurchaseService.proLifetimeId,
            allowSandboxSimulation: true,
          ),
          false,
        );
        expect(MonetizationService.isPro, false);
        await iap.setTesterSandbox(true);
        expect(iap.isTesterSandboxNotifier.value, false);
        expect(prefs.getBool('tally_iap_tester_sandbox'), isNull);
        expect(
          await iap.buyProduct('unknown', allowSandboxSimulation: true),
          false,
        );
      },
    );
    test(
      'all local paid-grant helpers and universal promo codes are disabled',
      () async {
        await MonetizationService.unlockPro();
        await MonetizationService.removeAds();
        await MonetizationService.unlockCoffeeWithTrial();
        for (final code in [
          'PROVIP',
          'TALLYPRO',
          'FINTECH2026',
          'UNLOCKALL',
          'NOADS',
          'THEMEPASS',
          'RESETVIP',
        ]) {
          expect(
            await MonetizationService.redeemPromoCode(code),
            'Promotion codes are not available.',
          );
        }
        expect(MonetizationService.isPro, false);
        expect(MonetizationService.isAdFree, false);
        expect(MonetizationService.isTrialActive, false);
      },
    );
    test(
      'even a valid legacy HMAC/premium cache is not a production entitlement',
      () async {
        const user = 'release-fixture';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tally_pro_unlocked_$user', true);
        await prefs.setBool('tally_ads_removed_$user', true);
        final signature = Hmac(
          sha256,
          utf8.encode('tally_vault_sec_hmac_2026_9x4b_pci:$user'),
        ).convert(utf8.encode('$user:true:true:0:')).toString();
        await prefs.setString('tally_monetization_sig_$user', signature);
        AppState.currentUser = user;
        await MonetizationService.loadUserEntitlements(user);
        expect(MonetizationService.isPro, false);
        expect(MonetizationService.isAdFree, false);
      },
    );
    testWidgets(
      'release-policy paywall hides developer reset and promo controls',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const MaterialApp(home: PremiumScreen()));
        await tester.pumpAndSettle();
        expect(find.textContaining('Reset VIP Subscription'), findsNothing);
        expect(find.text('Promo Code'), findsNothing);
        final pay = find.textContaining('Pay with Google Play').first;
        await tester.ensureVisible(pay);
        await tester.tap(pay);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Google Play is unavailable. No purchase has been started.',
          ),
          findsOneWidget,
        );
        expect(find.text('Authorize Sandbox Test Purchase'), findsNothing);
        expect(find.text('Development promo'), findsNothing);
      },
    );
  });

  group('Verified purchase delivery', () {
    test(
      'verification, delivery and store completion occur in that order',
      () async {
        final steps = <String>[];
        final backend = FakePurchaseBackend()
          ..work = () async {
            steps.add('verify');
            return verified();
          };
        final coordinator = PurchaseCoordinator(
          backend: backend,
          currentSession: () =>
              const PurchaseSession('alice', 'alice@example.test', 1),
          deliver: (value, session) async {
            expect(value.pro, true);
            steps.add('deliver');
          },
          now: () => now,
        );
        await coordinator.process(
          productId: 'tally_pro_lifetime',
          token: 'receipt',
          source: 'google_play',
          complete: () async {
            steps.add('complete');
          },
        );
        expect(steps, ['verify', 'deliver', 'complete']);
      },
    );
    for (final failure in [
      'network',
      'token',
      'product',
      'uid',
      'schema',
      'expired',
      'oversized-lease',
      'unverified',
    ]) {
      test('$failure cannot deliver or complete a purchase', () async {
        var delivered = false;
        var completed = false;
        final backend = FakePurchaseBackend()
          ..work = () async {
            if (failure == 'network') throw StateError('offline');
            final result = verified();
            final data = result['entitlements'] as Map<String, dynamic>;
            switch (failure) {
              case 'token':
                result['tokenHash'] = 'wrong';
              case 'product':
                result['productId'] = 'tally_remove_ads';
              case 'uid':
                data['uid'] = 'bob';
              case 'schema':
                data['schema'] = 1;
              case 'expired':
                data['leaseExpiresAtMs'] = now.millisecondsSinceEpoch - 1;
              case 'oversized-lease':
                data['leaseExpiresAtMs'] = now
                    .add(const Duration(days: 1))
                    .millisecondsSinceEpoch;
              case 'unverified':
                result['verified'] = false;
            }
            return result;
          };
        final coordinator = PurchaseCoordinator(
          backend: backend,
          currentSession: () =>
              const PurchaseSession('alice', 'alice@example.test', 1),
          deliver: (_, _) async {
            delivered = true;
          },
          now: () => now,
        );
        await expectLater(
          coordinator.process(
            productId: 'tally_pro_lifetime',
            token: 'receipt',
            source: 'google_play',
            complete: () async {
              completed = true;
            },
          ),
          throwsStateError,
        );
        expect(delivered, false);
        expect(completed, false);
      });
    }
    test(
      'account switch during verification cannot deliver into another account',
      () async {
        PurchaseSession? current = const PurchaseSession(
          'alice',
          'alice@example.test',
          1,
        );
        final backend = FakePurchaseBackend()
          ..work = () async {
            current = const PurchaseSession('bob', 'bob@example.test', 2);
            return verified();
          };
        var delivered = false;
        var completed = false;
        final coordinator = PurchaseCoordinator(
          backend: backend,
          currentSession: () => current,
          deliver: (_, _) async {
            delivered = true;
          },
          now: () => now,
        );
        await expectLater(
          coordinator.process(
            productId: 'tally_pro_lifetime',
            token: 'receipt',
            source: 'google_play',
            complete: () async {
              completed = true;
            },
          ),
          throwsStateError,
        );
        expect(delivered, false);
        expect(completed, false);
      },
    );
    test(
      'revoked purchase applies the server downgrade but is not acknowledged as a new grant',
      () async {
        final backend = FakePurchaseBackend()
          ..work = () async {
            final result = verified()..['active'] = false;
            (result['entitlements'] as Map<String, dynamic>)['pro_unlocked'] =
                false;
            return result;
          };
        var downgraded = false;
        var completed = false;
        final coordinator = PurchaseCoordinator(
          backend: backend,
          currentSession: () =>
              const PurchaseSession('alice', 'alice@example.test', 1),
          deliver: (lease, _) async {
            downgraded = !lease.pro;
          },
          now: () => now,
        );
        await expectLater(
          coordinator.process(
            productId: 'tally_pro_lifetime',
            token: 'receipt',
            source: 'google_play',
            complete: () async {
              completed = true;
            },
          ),
          throwsStateError,
        );
        expect(downgraded, true);
        expect(completed, false);
      },
    );
  });

  group('Server-authorized local password recovery', () {
    late FakeRecoveryBackend backend;
    late PasswordRecoveryService service;
    final db = AppDatabase.instance;
    const oldPassword = 'OldSecure123!';
    const newPassword = 'NewSecure456!';
    setUp(() async {
      final database = await db.database;
      await database.transaction((txn) async {
        for (final table in [
          'users',
          'profiles',
          'accounts',
          'budgets',
          'transactions',
          'goals',
          'goal_entries',
          'planned_transactions',
          'loans',
          'ledger_outbox',
        ]) {
          await txn.delete(table);
        }
      });
      await db.registerUser(
        username: 'alice',
        password: oldPassword,
        email: 'alice@example.test',
      );
      await db.registerUser(
        username: 'bob',
        password: oldPassword,
        email: 'bob@example.test',
      );
      backend = FakeRecoveryBackend();
      service = PasswordRecoveryService(backend: backend, database: db);
    });
    test(
      'verified mailbox code updates only its captured account and works after reopen',
      () async {
        await service.begin(' ALICE@example.test ');
        expect(backend.sentEmail, 'alice@example.test');
        await service.complete('123456', newPassword, newPassword);
        await db.close();
        expect(await db.authenticateUser('alice', newPassword), true);
        expect(await db.authenticateUser('alice', oldPassword), false);
        expect(await db.authenticateUser('bob', oldPassword), true);
        await expectLater(
          service.complete('123456', newPassword, newPassword),
          throwsStateError,
        );
        expect(backend.verifications, 1);
      },
    );
    for (final failure in [
      'unverified',
      'wrong-email',
      'wrong-challenge',
      'offline',
    ]) {
      test('$failure never changes the local password', () async {
        backend.onVerify = () async {
          if (failure == 'offline') throw StateError('offline');
          return {
            'verified': failure != 'unverified',
            'email': failure == 'wrong-email'
                ? 'bob@example.test'
                : 'alice@example.test',
            'challengeId': failure == 'wrong-challenge'
                ? 'other'
                : FakeRecoveryBackend.id,
          };
        };
        await service.begin('alice@example.test');
        await expectLater(
          service.complete('123456', newPassword, newPassword),
          throwsStateError,
        );
        expect(await db.authenticateUser('alice', oldPassword), true);
        expect(await db.authenticateUser('bob', oldPassword), true);
      });
    }
    test(
      'weak/mismatched passwords do not consume the server challenge',
      () async {
        await service.begin('alice@example.test');
        await expectLater(
          service.complete('123456', 'weak', 'weak'),
          throwsStateError,
        );
        await expectLater(
          service.complete('123456', newPassword, 'different'),
          throwsStateError,
        );
        expect(backend.verifications, 0);
      },
    );
    test(
      'changing a local password while recovery is in flight cannot be overwritten',
      () async {
        await service.begin('alice@example.test');
        await db.updatePasswordByEmail(
          'alice@example.test',
          'ChangedElsewhere789!',
        );
        await expectLater(
          service.complete('123456', newPassword, newPassword),
          throwsStateError,
        );
        expect(
          await db.authenticateUser('alice', 'ChangedElsewhere789!'),
          true,
        );
      },
    );
    test(
      'canceling pending verification prevents a later response from changing credentials',
      () async {
        final pending = Completer<Map<String, dynamic>>();
        backend.onVerify = () => pending.future;
        await service.begin('alice@example.test');
        final operation = service.complete('123456', newPassword, newPassword);
        final assertion = expectLater(operation, throwsStateError);
        service.cancel();
        pending.complete({
          'verified': true,
          'email': 'alice@example.test',
          'challengeId': FakeRecoveryBackend.id,
        });
        await assertion;
        expect(await db.authenticateUser('alice', oldPassword), true);
      },
    );
    testWidgets('email failure is visible and never advances to code entry', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordRecoveryDialog(
            initialEmail: 'alice@example.test',
            service: DeliveryFailureRecoveryService(),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('recovery_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Email delivery unavailable'), findsOneWidget);
      expect(find.byKey(const Key('recovery_code')), findsNothing);
    });
  });
}
