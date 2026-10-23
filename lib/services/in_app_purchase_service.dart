import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monetization_service.dart';
import 'purchase_backend.dart';

class InAppPurchaseService {
  InAppPurchaseService._();
  static final InAppPurchaseService instance = InAppPurchaseService._();
  static const String proMonthlyId = 'tally_pro_monthly';
  static const String proYearlyId = 'tally_pro_yearly';
  static const String proLifetimeId = 'tally_pro_lifetime';
  static const String removeAdsId = 'tally_remove_ads';
  static const String coffeeTipId = 'tally_coffee_tip';
  static const Set<String> productIds = {
    proMonthlyId,
    proYearlyId,
    proLifetimeId,
    removeAdsId,
    coffeeTipId,
  };
  InAppPurchase? _iap;
  InAppPurchase get iap => _iap ??= InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final PurchaseBackend _backend = FirebasePurchaseBackend();
  final ValueNotifier<bool> isStoreAvailableNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPurchasePendingNotifier = ValueNotifier(false);
  final ValueNotifier<Map<String, ProductDetails>> productsNotifier =
      ValueNotifier({});
  final ValueNotifier<String?> lastErrorNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isTesterSandboxNotifier = ValueNotifier(false);

  Future<void> setTesterSandbox(bool enabled) async {
    final allowed = PurchaseSecurityPolicy.allowDevelopmentUnlocks && enabled;
    isTesterSandboxNotifier.value = allowed;
    final prefs = await SharedPreferences.getInstance();
    if (allowed) {
      await prefs.setBool('tally_iap_tester_sandbox', true);
    } else {
      await prefs.remove('tally_iap_tester_sandbox');
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    isTesterSandboxNotifier.value =
        PurchaseSecurityPolicy.allowDevelopmentUnlocks &&
        (prefs.getBool('tally_iap_tester_sandbox') ?? false);
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks) {
      await prefs.remove('tally_iap_tester_sandbox');
    }
    // Google Play only. Unsupported platforms cannot fall into a production simulator.
    if (kIsWeb || !Platform.isAndroid) {
      isStoreAvailableNotifier.value = false;
      return;
    }
    try {
      // Attach before querying store availability/products so early restore events are retained.
      await _subscription?.cancel();
      _subscription = iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (_) {
          lastErrorNotifier.value =
              'Store communication failed. Restore purchases to retry.';
          isPurchasePendingNotifier.value = false;
        },
      );
      isStoreAvailableNotifier.value = await iap.isAvailable();
      if (isStoreAvailableNotifier.value) await queryProducts();
    } catch (_) {
      isStoreAvailableNotifier.value = false;
      lastErrorNotifier.value = 'Google Play is unavailable.';
    }
  }

  Future<void> queryProducts() async {
    try {
      final result = await iap.queryProductDetails(productIds);
      productsNotifier.value = {
        for (final product in result.productDetails) product.id: product,
      };
      if (result.error != null) lastErrorNotifier.value = result.error!.message;
    } catch (_) {
      lastErrorNotifier.value = 'Could not load Google Play products.';
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasePendingNotifier.value = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          isPurchasePendingNotifier.value = true;
          try {
            await PurchaseCoordinator(
              backend: _backend,
              currentSession: MonetizationService.currentPurchaseSession,
              deliver: MonetizationService.applyVerifiedLease,
            ).process(
              productId: purchase.productID,
              token: purchase.verificationData.serverVerificationData,
              source: purchase.verificationData.source,
              complete: () async {
                // Server consumption acknowledges the consumable. Asking Play
                // to acknowledge that consumed token again can fail as not owned.
                if (purchase.productID != coffeeTipId &&
                    purchase.pendingCompletePurchase) {
                  await iap.completePurchase(purchase);
                }
              },
            );
            lastErrorNotifier.value = null;
          } catch (_) {
            // Do not complete/acknowledge an unverified purchase. The store can redeliver it.
            lastErrorNotifier.value =
                'Purchase could not be verified. Check your Google account and restore purchases to retry.';
          } finally {
            isPurchasePendingNotifier.value = false;
          }
        case PurchaseStatus.error:
          isPurchasePendingNotifier.value = false;
          lastErrorNotifier.value =
              purchase.error?.message ?? 'Purchase failed.';
        case PurchaseStatus.canceled:
          isPurchasePendingNotifier.value = false;
      }
    }
  }

  Future<bool> buyProduct(
    String productId, {
    bool allowSandboxSimulation = false,
  }) async {
    if (!productIds.contains(productId)) {
      lastErrorNotifier.value = 'Unknown product.';
      return false;
    }
    final product = productsNotifier.value[productId];
    if (isStoreAvailableNotifier.value && product != null) {
      final session = MonetizationService.currentPurchaseSession();
      if (session == null) {
        lastErrorNotifier.value = 'Sign in with Google before purchasing.';
        return false;
      }
      final param = PurchaseParam(
        productDetails: product,
        applicationUserName: sha256
            .convert(utf8.encode(session.uid))
            .toString(),
      );
      isPurchasePendingNotifier.value = true;
      lastErrorNotifier.value = null;
      try {
        final started = productId == coffeeTipId
            ? await iap.buyConsumable(purchaseParam: param, autoConsume: false)
            : await iap.buyNonConsumable(purchaseParam: param);
        if (!started) isPurchasePendingNotifier.value = false;
        return started; // Store launch is not a verified purchase.
      } catch (_) {
        isPurchasePendingNotifier.value = false;
        lastErrorNotifier.value = 'Could not start the Google Play purchase.';
        return false;
      }
    }
    final canSimulate =
        PurchaseSecurityPolicy.allowDevelopmentUnlocks &&
        (allowSandboxSimulation ||
            isTesterSandboxNotifier.value ||
            !kReleaseMode);
    if (!canSimulate) {
      isPurchasePendingNotifier.value = false;
      lastErrorNotifier.value =
          'Google Play or this product is unavailable. No payment or unlock has occurred.';
      return false;
    }
    // Explicitly development-only; the immutable release gate wins over preferences/arguments.
    if (productId == proMonthlyId ||
        productId == proYearlyId ||
        productId == proLifetimeId) {
      await MonetizationService.unlockPro();
    } else if (productId == removeAdsId) {
      await MonetizationService.removeAds();
    } else {
      await MonetizationService.unlockCoffeeWithTrial();
    }
    return true;
  }

  Future<void> restorePurchases() async {
    await MonetizationService.refreshVerifiedEntitlements();
    final session = MonetizationService.currentPurchaseSession();
    if (!isStoreAvailableNotifier.value || session == null) {
      lastErrorNotifier.value =
          'Sign in with Google and connect to Google Play to restore purchases.';
      return;
    }
    try {
      await iap.restorePurchases(
        applicationUserName: sha256
            .convert(utf8.encode(session.uid))
            .toString(),
      );
    } catch (_) {
      lastErrorNotifier.value =
          'Could not restore purchases. Please try again.';
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
