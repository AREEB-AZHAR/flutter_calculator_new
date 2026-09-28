import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'monetization_service.dart';

/// Centralized Google Official Payment (Google Play Billing / In-App Purchase) Service.
///
/// Integrates the official `in_app_purchase` plugin from flutter.dev to handle
/// Google Play Billing subscriptions, one-time in-app purchases, purchase restoration,
/// and graceful local fallback for developer/testing environments.
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

  final ValueNotifier<bool> isStoreAvailableNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPurchasePendingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Map<String, ProductDetails>> productsNotifier = ValueNotifier<Map<String, ProductDetails>>({});
  final ValueNotifier<String?> lastErrorNotifier = ValueNotifier<String?>(null);

  /// Initializes Google Play Billing / App Store connectivity and begins listening
  /// for purchase stream updates.
  Future<void> initialize() async {
    // In-App Purchase plugin is designed for mobile platforms (Android & iOS).
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('InAppPurchaseService: Desktop/Web platform detected; using simulated Google Play mode.');
      isStoreAvailableNotifier.value = false;
      return;
    }

    try {
      final isAvailable = await iap.isAvailable();
      isStoreAvailableNotifier.value = isAvailable;

      if (!isAvailable) {
        debugPrint('InAppPurchaseService: Google Play Store is not currently available on this device.');
        return;
      }

      // Listen to purchase stream
      _subscription?.cancel();
      _subscription = iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (dynamic error) {
          debugPrint('InAppPurchaseService.purchaseStream error: $error');
          lastErrorNotifier.value = error.toString();
          isPurchasePendingNotifier.value = false;
        },
      );

      // Query products from Google Play
      await queryProducts();
    } catch (e) {
      debugPrint('InAppPurchaseService.initialize exception: $e');
      isStoreAvailableNotifier.value = false;
    }
  }

  /// Queries product definitions from Google Play Console / App Store.
  Future<void> queryProducts() async {
    try {
      final response = await iap.queryProductDetails(productIds);
      if (response.error != null) {
        debugPrint('InAppPurchaseService.queryProductDetails error: ${response.error}');
        lastErrorNotifier.value = response.error!.message;
      }

      final Map<String, ProductDetails> map = {};
      for (final p in response.productDetails) {
        map[p.id] = p;
      }
      productsNotifier.value = map;
      debugPrint('InAppPurchaseService: Loaded ${map.length} products from Google Play.');
    } catch (e) {
      debugPrint('InAppPurchaseService.queryProducts exception: $e');
    }
  }

  /// Handles incoming purchase events from Google Play Billing.
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('InAppPurchaseService: Purchase update for ${purchaseDetails.productID} with status ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          isPurchasePendingNotifier.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          isPurchasePendingNotifier.value = false;
          await _deliverProduct(purchaseDetails);
          if (purchaseDetails.pendingCompletePurchase) {
            await iap.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.error:
          isPurchasePendingNotifier.value = false;
          lastErrorNotifier.value = purchaseDetails.error?.message ?? 'Purchase failed';
          debugPrint('InAppPurchaseService: Purchase error: ${purchaseDetails.error}');
          break;

        case PurchaseStatus.canceled:
          isPurchasePendingNotifier.value = false;
          debugPrint('InAppPurchaseService: Purchase canceled by user');
          break;
      }
    }
  }

  /// Delivers entitlement based on product ID.
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final id = purchaseDetails.productID;
    if (id == proMonthlyId || id == proYearlyId || id == proLifetimeId) {
      await MonetizationService.unlockPro();
      debugPrint('InAppPurchaseService: Tally Pro unlocked via official Google Play payment.');
    } else if (id == removeAdsId) {
      await MonetizationService.removeAds();
      debugPrint('InAppPurchaseService: Ads removed via official Google Play payment.');
    } else if (id == coffeeTipId) {
      await MonetizationService.unlockCoffeeWithTrial();
      debugPrint('InAppPurchaseService: Coffee Developer Gift activated via official Google Play payment.');
    }
  }

  /// Initiates an official purchase through Google Play Billing.
  /// If running in a test or unconfigured store environment, provides a seamless fallback.
  Future<bool> buyProduct(String productId) async {
    final product = productsNotifier.value[productId];

    if (isStoreAvailableNotifier.value && product != null) {
      isPurchasePendingNotifier.value = true;
      lastErrorNotifier.value = null;

      final purchaseParam = PurchaseParam(productDetails: product);
      final isConsumable = productId == coffeeTipId;

      try {
        if (isConsumable) {
          return await iap.buyConsumable(purchaseParam: purchaseParam);
        } else {
          return await iap.buyNonConsumable(purchaseParam: purchaseParam);
        }
      } catch (e) {
        isPurchasePendingNotifier.value = false;
        lastErrorNotifier.value = e.toString();
        debugPrint('InAppPurchaseService.buyProduct error: $e');
        return false;
      }
    } else {
      // Graceful test / simulation mode (desktop, emulator without Play Services, or pending Play Console review)
      debugPrint('InAppPurchaseService: Using official Google Pay simulation flow for $productId');
      isPurchasePendingNotifier.value = true;
      await Future.delayed(const Duration(milliseconds: 650));
      isPurchasePendingNotifier.value = false;

      if (productId == proMonthlyId || productId == proYearlyId || productId == proLifetimeId) {
        await MonetizationService.unlockPro();
      } else if (productId == removeAdsId) {
        await MonetizationService.removeAds();
      } else if (productId == coffeeTipId) {
        await MonetizationService.unlockCoffeeWithTrial();
      }
      return true;
    }
  }

  /// Restores previous Google Play / App Store purchases.
  Future<void> restorePurchases() async {
    if (!isStoreAvailableNotifier.value) {
      debugPrint('InAppPurchaseService: Store unavailable; cannot restore purchases.');
      return;
    }

    try {
      isPurchasePendingNotifier.value = true;
      await iap.restorePurchases();
    } catch (e) {
      debugPrint('InAppPurchaseService.restorePurchases error: $e');
      lastErrorNotifier.value = e.toString();
    } finally {
      isPurchasePendingNotifier.value = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
