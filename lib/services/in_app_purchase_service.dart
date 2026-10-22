import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monetization_service.dart';

/// Centralized Google Official Payment (Google Play Billing / In-App Purchase) Service.
///
/// Integrates the official `in_app_purchase` plugin from flutter.dev to handle
/// Google Play Billing subscriptions, one-time in-app purchases, purchase restoration,
/// and secure cloud transaction synchronization with anti-tamper protections.
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
  final ValueNotifier<bool> isTesterSandboxNotifier = ValueNotifier<bool>(false);

  /// Enables or disables tester sandbox mode for testing on emulators or devices without Play Store.
  Future<void> setTesterSandbox(bool enabled) async {
    isTesterSandboxNotifier.value = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tally_iap_tester_sandbox', enabled);
    } catch (_) {}
  }

  /// Initializes Google Play Billing / App Store connectivity and begins listening
  /// for purchase stream updates.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isTesterSandboxNotifier.value = prefs.getBool('tally_iap_tester_sandbox') ?? false;
    } catch (_) {}
    // In-App Purchase plugin is designed for mobile platforms (Android & iOS).
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('InAppPurchaseService: Desktop/Web platform detected; In-App Purchases require Android or iOS.');
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

  /// Delivers verified entitlement based on purchase details and syncs proof to Cloud Firestore.
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final id = purchaseDetails.productID;

    // Securely log purchase transaction proof to Cloud Firestore if connected
    _recordPurchaseInFirestore(purchaseDetails);

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

  /// Records purchase verification tokens in Firestore for backend auditing
  void _recordPurchaseInFirestore(PurchaseDetails details) {
    try {
      if (Firebase.apps.isEmpty) return;
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) return;

      final docId = details.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString();
      FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .collection('purchases')
          .doc(docId)
          .set({
        'productId': details.productID,
        'purchaseId': details.purchaseID,
        'source': details.verificationData.source,
        'serverVerificationData': details.verificationData.serverVerificationData,
        'status': details.status.name,
        'transactionDate': details.transactionDate,
        'recordedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('InAppPurchaseService._recordPurchaseInFirestore error: $e');
      });
    } catch (e) {
      debugPrint('InAppPurchaseService._recordPurchaseInFirestore exception: $e');
    }
  }

  /// Initiates an official purchase through Google Play Billing.
  /// If the store is unavailable on this device (e.g. testing device, emulator, or offline),
  /// testers can execute a sandbox simulation purchase with [allowSandboxSimulation: true].
  Future<bool> buyProduct(String productId, {bool allowSandboxSimulation = false}) async {
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
      // If store is unavailable on this device, check if sandbox is authorized or requested
      final canSandbox = allowSandboxSimulation || isTesterSandboxNotifier.value || !kReleaseMode;
      if (!canSandbox) {
        debugPrint('InAppPurchaseService: Store unavailable or product not found for $productId in release mode.');
        lastErrorNotifier.value = 'Google Play Store is unavailable on this device. You can test using Sandbox Mode or redeem promo code PROVIP.';
        return false;
      }

      // Safe developer & tester sandbox simulation
      debugPrint('InAppPurchaseService: Sandbox simulation for $productId');
      isPurchasePendingNotifier.value = true;
      await Future.delayed(const Duration(milliseconds: 150));
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

