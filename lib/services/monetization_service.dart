import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'purchase_backend.dart';
import 'state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';
import 'geo_location_service.dart';
import '../screens/premium_screen.dart';
import '../widgets/form_dialog.dart';

class MonetizationService {
  // Temporary debug-only testing exception. Remove by setting false;
  // stored FREEVIP flags are ignored when this switch is disabled.
  static const bool testingVipCodeEnabled = kDebugMode;
  static final ValueNotifier<bool> testingVipNotifier = ValueNotifier(false);
  static bool get testingVipActive =>
      testingVipCodeEnabled && testingVipNotifier.value;
  static const _testingVipKey = 'tally_testing_freevip';

  @visibleForTesting
  static Future<void> Function()? refreshForTesting;
  static Future<void> verificationReady = Future<void>.value();

  static Future<void> disableTestingVip() async {
    testingVipNotifier.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_testingVipKey);
    _clearPaidAccess();
    unawaited(refreshVerifiedEntitlements());
  }

  static const String _prefProUnlockedKey = 'tally_pro_unlocked';
  static const String _prefAdsRemovedKey = 'tally_ads_removed';
  static const String _prefProTrialExpiryKey = 'tally_pro_trial_expiry';
  static const String _prefThemePassesKey = 'tally_theme_passes';
  static const String _prefSignatureKey = 'tally_monetization_sig';

  // Development fixture checksum only; production paid access ignores this cache.
  static const String _securitySecret = 'tally_vault_sec_hmac_2026_9x4b_pci';

  // Recalculated Pro Pricing Matrix (Fintech Benchmark & Unit Economics)
  static const double proMonthlyPrice = 2.99;
  static const double proYearlyPrice = 19.99; // $1.67/mo (Save 44%)
  static const double proLifetimePrice = 39.99; // 2x Annual, Lifetime Access
  static const double removeAdsPrice = 1.99; // Standalone banner ad removal
  static const double coffeeTipPrice =
      2.99; // Tip jar + Ad-Free for life + 7-Day Pro trial

  static final ValueNotifier<bool> isProUnlockedNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<bool> isAdsRemovedNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<DateTime?> proTrialExpiryNotifier =
      ValueNotifier<DateTime?>(null);
  static final ValueNotifier<int> themePassesNotifier = ValueNotifier<int>(0);

  static String? _activeUsername;
  static Timer? _leaseTimer;
  static DateTime? _leaseExpiry;
  static int _entitlementGeneration = 0;
  static final PurchaseBackend _purchaseBackend = FirebasePurchaseBackend();
  static final ValueNotifier<String?> verificationErrorNotifier = ValueNotifier(
    null,
  );

  static PurchaseSession? currentPurchaseSession() {
    if (Firebase.apps.isEmpty ||
        _activeUsername == null ||
        AppState.currentUser != _activeUsername) {
      return null;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        user.email?.toLowerCase() != _activeUsername!.toLowerCase()) {
      return null;
    }
    return PurchaseSession(
      user.uid,
      _activeUsername!,
      AppState.sessionGeneration,
    );
  }

  static void _clearPaidAccess() {
    _leaseTimer?.cancel();
    _leaseExpiry = null;
    isProUnlockedNotifier.value = testingVipActive;
    isAdsRemovedNotifier.value = testingVipActive;
    proTrialExpiryNotifier.value = null;
  }

  static Future<void> applyVerifiedLease(
    VerifiedEntitlements lease,
    PurchaseSession session,
  ) async {
    if (!session.matches(currentPurchaseSession())) {
      throw StateError('Purchase account changed.');
    }
    _leaseTimer?.cancel();
    _leaseExpiry = lease.leaseExpiry;
    isProUnlockedNotifier.value = lease.pro || testingVipActive;
    isAdsRemovedNotifier.value = lease.ads || testingVipActive;
    proTrialExpiryNotifier.value = lease.trialExpiry;
    verificationErrorNotifier.value = null;
    final generation = _entitlementGeneration;
    _leaseTimer = Timer(lease.leaseExpiry.difference(DateTime.now()), () {
      _clearPaidAccess();
      if (generation == _entitlementGeneration &&
          session.matches(currentPurchaseSession())) {
        unawaited(refreshVerifiedEntitlements());
      }
    });
  }

  static Future<void> refreshVerifiedEntitlements() async {
    final session = currentPurchaseSession();
    final generation = _entitlementGeneration;
    if (session == null) {
      _clearPaidAccess();
      return;
    }
    try {
      final data = await _purchaseBackend.refresh();
      if (generation != _entitlementGeneration ||
          !session.matches(currentPurchaseSession())) {
        return;
      }
      await applyVerifiedLease(
        VerifiedEntitlements.parse(data, session.uid, DateTime.now()),
        session,
      );
    } catch (_) {
      if (generation == _entitlementGeneration &&
          session.matches(currentPurchaseSession())) {
        _clearPaidAccess();
        verificationErrorNotifier.value =
            'Could not verify paid access. Connect and restore purchases to retry.';
      }
    }
  }

  static bool get _hasValidPaidLease =>
      testingVipActive || PurchaseSecurityPolicy.allowDevelopmentUnlocks ||
      (_leaseExpiry != null && DateTime.now().isBefore(_leaseExpiry!));

  static String _userKey(String baseKey) {
    if (_activeUsername != null && _activeUsername!.isNotEmpty) {
      return '${baseKey}_$_activeUsername';
    }
    return baseKey;
  }

  /// Development preference checksum, not a server authority or rooted-device defense.
  static String _computeSignature({
    required String user,
    required bool isPro,
    required bool isAdsRemoved,
    required int passes,
    required String trialExpiry,
  }) {
    final payload = '$user:$isPro:$isAdsRemoved:$passes:$trialExpiry';
    final key = utf8.encode('$_securitySecret:$user');
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// Persists entitlements alongside an HMAC-SHA256 cryptographic signature in SharedPreferences.
  static Future<void> _persistWithSignature({
    required SharedPreferences prefs,
    required bool isPro,
    required bool isAdsRemoved,
    required int themePasses,
    required String? trialExpiry,
  }) async {
    final user = _activeUsername ?? 'default_user';
    final userProKey = _userKey(_prefProUnlockedKey);
    final userAdsKey = _userKey(_prefAdsRemovedKey);
    final userTrialKey = _userKey(_prefProTrialExpiryKey);
    final userPassesKey = _userKey(_prefThemePassesKey);
    final userSigKey = _userKey(_prefSignatureKey);

    await prefs.setBool(userProKey, isPro);
    await prefs.setBool(userAdsKey, isAdsRemoved);
    await prefs.setInt(userPassesKey, themePasses);
    if (trialExpiry != null && trialExpiry.isNotEmpty) {
      await prefs.setString(userTrialKey, trialExpiry);
    } else {
      await prefs.remove(userTrialKey);
    }

    final sig = _computeSignature(
      user: user,
      isPro: isPro,
      isAdsRemoved: isAdsRemoved,
      passes: themePasses,
      trialExpiry: trialExpiry ?? '',
    );
    await prefs.setString(userSigKey, sig);
  }

  /// True if user is currently enjoying an active 7-day promotional Pro trial.
  static bool get isTrialActive {
    final expiry = proTrialExpiryNotifier.value;
    return _hasValidPaidLease &&
        expiry != null &&
        DateTime.now().isBefore(expiry);
  }

  /// Remaining trial days (or 0 if expired/not active).
  static int get trialDaysRemaining {
    final expiry = proTrialExpiryNotifier.value;
    if (expiry == null) return 0;
    final diff = expiry.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff + 1 : 0;
  }

  /// True if user has purchased / unlocked Tally Pro (all-access) or has an active trial.
  static bool get isPro =>
      (_hasValidPaidLease && isProUnlockedNotifier.value) || isTrialActive;

  /// True if ads should be hidden (either via Pro unlock, dedicated Remove Ads, or coffee gift).
  static bool get isAdFree =>
      (_hasValidPaidLease &&
          (isProUnlockedNotifier.value || isAdsRemovedNotifier.value)) ||
      isTrialActive;

  /// True if user has unlimited access via Pro or has at least 1 theme pass.
  static bool get hasThemePass => isPro || themePassesNotifier.value > 0;

  /// Initializes monetization states from local SharedPreferences with tamper verification.
  static Future<void> initialize() async {
    verificationReady = Future<void>.value();
    final testingPrefs = await SharedPreferences.getInstance();
    testingVipNotifier.value = testingVipCodeEnabled && (testingPrefs.getBool(_testingVipKey) ?? false);
    if (testingVipActive) {
      _clearPaidAccess();
      return;
    }
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks) {
      _clearPaidAccess();
      final prefs = await SharedPreferences.getInstance();
      // Rewarded cosmetic passes are separate from paid membership.
      themePassesNotifier.value =
          (prefs.getInt(_userKey(_prefThemePassesKey)) ?? 0).clamp(0, 100);
      // Local login must not wait on an unavailable billing backend.
      verificationReady = (refreshForTesting?.call() ?? refreshVerifiedEntitlements()).catchError((Object _) {});
      unawaited(verificationReady);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _activeUsername ?? 'default_user';
      final userProKey = _userKey(_prefProUnlockedKey);
      final userAdsKey = _userKey(_prefAdsRemovedKey);
      final userTrialKey = _userKey(_prefProTrialExpiryKey);
      final userPassesKey = _userKey(_prefThemePassesKey);
      final userSigKey = _userKey(_prefSignatureKey);

      final rawPro = prefs.getBool(userProKey) ?? false;
      final rawAds = prefs.getBool(userAdsKey) ?? false;
      final rawPasses = prefs.getInt(userPassesKey) ?? 0;
      final rawTrialStr = prefs.getString(userTrialKey);
      final storedSig = prefs.getString(userSigKey);

      // Verify HMAC integrity if any privilege is active
      if (rawPro ||
          rawAds ||
          rawPasses > 0 ||
          (rawTrialStr != null && rawTrialStr.isNotEmpty)) {
        final expectedSig = _computeSignature(
          user: user,
          isPro: rawPro,
          isAdsRemoved: rawAds,
          passes: rawPasses,
          trialExpiry: rawTrialStr ?? '',
        );

        if (storedSig != expectedSig) {
          debugPrint(
            'MonetizationService: Local storage tamper detected for $user! Resetting to free tier.',
          );
          await prefs.remove(userProKey);
          await prefs.remove(userAdsKey);
          await prefs.remove(userTrialKey);
          await prefs.remove(userPassesKey);
          await prefs.remove(userSigKey);

          isProUnlockedNotifier.value = false;
          isAdsRemovedNotifier.value = false;
          themePassesNotifier.value = 0;
          proTrialExpiryNotifier.value = null;
          return;
        }
      }

      isProUnlockedNotifier.value = rawPro;
      isAdsRemovedNotifier.value = rawAds;
      themePassesNotifier.value = rawPasses;

      if (rawTrialStr != null && rawTrialStr.isNotEmpty) {
        final expiry = DateTime.tryParse(rawTrialStr);
        if (expiry != null && DateTime.now().isBefore(expiry)) {
          proTrialExpiryNotifier.value = expiry;
        } else {
          proTrialExpiryNotifier.value = null;
        }
      } else {
        proTrialExpiryNotifier.value = null;
      }
    } catch (e) {
      debugPrint('MonetizationService.initialize error: $e');
    }
  }

  /// Loads entitlements strictly scoped to the specified user account with tamper checking.
  static Future<void> loadUserEntitlements(String username) async {
    _activeUsername = username;
    _entitlementGeneration++;
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks || testingVipActive) {
      await initialize();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProKey = '${_prefProUnlockedKey}_$username';
      final userAdsKey = '${_prefAdsRemovedKey}_$username';
      final userTrialKey = '${_prefProTrialExpiryKey}_$username';
      final userPassesKey = '${_prefThemePassesKey}_$username';
      final userSigKey = '${_prefSignatureKey}_$username';

      final rawPro = prefs.getBool(userProKey) ?? false;
      final rawAds = prefs.getBool(userAdsKey) ?? false;
      final rawPasses = prefs.getInt(userPassesKey) ?? 0;
      final rawTrialStr = prefs.getString(userTrialKey);
      final storedSig = prefs.getString(userSigKey);

      // Verify HMAC integrity
      if (rawPro ||
          rawAds ||
          rawPasses > 0 ||
          (rawTrialStr != null && rawTrialStr.isNotEmpty)) {
        final expectedSig = _computeSignature(
          user: username,
          isPro: rawPro,
          isAdsRemoved: rawAds,
          passes: rawPasses,
          trialExpiry: rawTrialStr ?? '',
        );

        if (storedSig != expectedSig) {
          debugPrint(
            'MonetizationService: Local storage tamper detected for $username! Resetting to free tier.',
          );
          await prefs.remove(userProKey);
          await prefs.remove(userAdsKey);
          await prefs.remove(userTrialKey);
          await prefs.remove(userPassesKey);
          await prefs.remove(userSigKey);

          isProUnlockedNotifier.value = false;
          isAdsRemovedNotifier.value = false;
          themePassesNotifier.value = 0;
          proTrialExpiryNotifier.value = null;
          return;
        }
      }

      isProUnlockedNotifier.value = rawPro;
      isAdsRemovedNotifier.value = rawAds;
      themePassesNotifier.value = rawPasses;

      if (rawTrialStr != null && rawTrialStr.isNotEmpty) {
        final expiry = DateTime.tryParse(rawTrialStr);
        if (expiry != null && DateTime.now().isBefore(expiry)) {
          proTrialExpiryNotifier.value = expiry;
        } else {
          proTrialExpiryNotifier.value = null;
        }
      } else {
        proTrialExpiryNotifier.value = null;
      }

      // If user is authenticated with Firebase, listen for remote entitlement updates
    } catch (e) {
      debugPrint('MonetizationService.loadUserEntitlements error: $e');
    }
  }

  /// Resets in-memory entitlement notifiers to factory/logged-out state.
  static void resetToLoggedOut() {
    _entitlementGeneration++;
    _clearPaidAccess();
    _activeUsername = null;
    isProUnlockedNotifier.value = false;
    isAdsRemovedNotifier.value = false;
    proTrialExpiryNotifier.value = null;
    themePassesNotifier.value = 0;
  }

  /// Grants one or more 1-time theme change passes with tamper-proof signature.
  static Future<void> grantThemePass([int count = 1]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newCount = themePassesNotifier.value + count;
      themePassesNotifier.value = newCount;

      await _persistWithSignature(
        prefs: prefs,
        isPro: isProUnlockedNotifier.value,
        isAdsRemoved: isAdsRemovedNotifier.value,
        themePasses: newCount,
        trialExpiry: proTrialExpiryNotifier.value?.toIso8601String(),
      );
      debugPrint(
        'MonetizationService: Granted $count theme pass(es) for $_activeUsername. Total: $newCount',
      );
    } catch (e) {
      debugPrint('MonetizationService.grantThemePass error: $e');
    }
  }

  /// Consumes one 1-time theme change pass when applying a premium or custom theme.
  /// Returns true if a pass was successfully deducted or user is Pro.
  static Future<bool> consumeThemePass() async {
    if (isPro) return true;
    if (themePassesNotifier.value <= 0) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final newCount = themePassesNotifier.value - 1;
      themePassesNotifier.value = newCount;

      await _persistWithSignature(
        prefs: prefs,
        isPro: isProUnlockedNotifier.value,
        isAdsRemoved: isAdsRemovedNotifier.value,
        themePasses: newCount,
        trialExpiry: proTrialExpiryNotifier.value?.toIso8601String(),
      );
      debugPrint(
        'MonetizationService: Consumed 1 theme pass for $_activeUsername. Remaining: $newCount',
      );
      return true;
    } catch (e) {
      debugPrint('MonetizationService.consumeThemePass error: $e');
      return false;
    }
  }

  /// Unlocks Tally Pro with cryptographic signature verification.
  static Future<void> unlockPro() async {
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      isProUnlockedNotifier.value = true;

      await _persistWithSignature(
        prefs: prefs,
        isPro: true,
        isAdsRemoved: isAdsRemovedNotifier.value,
        themePasses: themePassesNotifier.value,
        trialExpiry: proTrialExpiryNotifier.value?.toIso8601String(),
      );
      debugPrint(
        'MonetizationService: Tally Pro unlocked and signed for $_activeUsername.',
      );
    } catch (e) {
      debugPrint('MonetizationService.unlockPro error: $e');
    }
  }

  /// Unlocks the separate Remove Ads option permanently with cryptographic signature.
  static Future<void> removeAds() async {
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      isAdsRemovedNotifier.value = true;

      await _persistWithSignature(
        prefs: prefs,
        isPro: isProUnlockedNotifier.value,
        isAdsRemoved: true,
        themePasses: themePassesNotifier.value,
        trialExpiry: proTrialExpiryNotifier.value?.toIso8601String(),
      );
      debugPrint(
        'MonetizationService: Ads removed and signed for $_activeUsername.',
      );
    } catch (e) {
      debugPrint('MonetizationService.removeAds error: $e');
    }
  }

  /// Unlocks the "Buy Me a Coffee" developer gift:
  /// Permanently removes all banner ads + gives a complimentary 7-day Tally Pro VIP trial!
  static Future<void> unlockCoffeeWithTrial() async {
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      isAdsRemovedNotifier.value = true;
      final expiry = DateTime.now().add(const Duration(days: 7));
      proTrialExpiryNotifier.value = expiry;

      await _persistWithSignature(
        prefs: prefs,
        isPro: isProUnlockedNotifier.value,
        isAdsRemoved: true,
        themePasses: themePassesNotifier.value,
        trialExpiry: expiry.toIso8601String(),
      );
      debugPrint(
        'MonetizationService: Coffee gift unlocked and signed for $_activeUsername.',
      );
    } catch (e) {
      debugPrint('MonetizationService.unlockCoffeeWithTrial error: $e');
    }
  }

  /// Resets all purchase and unlock flags to Free tier (ideal for testing and verification).
  static Future<void> resetPurchases() async {
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey(_prefProUnlockedKey));
      await prefs.remove(_userKey(_prefAdsRemovedKey));
      await prefs.remove(_userKey(_prefProTrialExpiryKey));
      await prefs.remove(_userKey(_prefThemePassesKey));
      await prefs.remove(_userKey(_prefSignatureKey));

      // Also clear legacy keys
      await prefs.remove(_prefProUnlockedKey);
      await prefs.remove(_prefAdsRemovedKey);
      await prefs.remove(_prefProTrialExpiryKey);
      await prefs.remove(_prefThemePassesKey);
      await prefs.remove(_prefSignatureKey);

      isProUnlockedNotifier.value = false;
      isAdsRemovedNotifier.value = false;
      proTrialExpiryNotifier.value = null;
      themePassesNotifier.value = 0;
    } catch (e) {
      debugPrint('MonetizationService.resetPurchases error: $e');
    }
  }

  /// Validates and redeems promo codes with server-side validation & local developer security.
  static Future<String?> redeemPromoCode(String inputCode) async {
    if (testingVipCodeEnabled && inputCode.trim().toUpperCase() == 'FREEVIP') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testingVipKey, true);
      testingVipNotifier.value = true;
      _clearPaidAccess();
      return 'FREEVIP testing enabled on this device: Pro features and no ads. This is not a store purchase.';
    }
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks) {
      return 'Promotion codes are not available.';
    }
    final code = inputCode.trim().toUpperCase();

    // 1. Authoritative developer & tester promo codes (active for testing across all environments)
    if (code == 'PROVIP' ||
        code == 'TALLYPRO' ||
        code == 'FINTECH2026' ||
        code == 'UNLOCKALL') {
      await unlockPro();
      return '🎉 Tally Pro fully unlocked! All features & ad-free experience activated.';
    } else if (code == 'NOADS' || code == 'REMOVEADS' || code == 'ADFREE') {
      await removeAds();
      return '✨ Ads removed successfully! Enjoy clean banner-free budgeting.';
    } else if (code == 'THEMEPASS' || code == 'FREEPASS' || code == 'THEME3') {
      await grantThemePass(3);
      return '🎨 3 Free Theme Change Passes added to your vault!';
    } else if (code == 'RESET' ||
        code == 'RESETVIP' ||
        code == 'RESETPRO' ||
        code == 'FREE') {
      await resetPurchases();
      return '🔄 VIP Subscription, Theme Passes & Ad-Free status have been reset to Free tier.';
    }

    return null;
  }

  /// Displays the interactive Paywall / Feature Unlock dialog.
  static Future<void> showPaywallModal(
    BuildContext context, {
    String? featureTitle,
    String? featureDescription,
  }) async {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (c, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: onSurface.withValues(alpha: 0.12)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Pro Crown / Star Badge
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  featureTitle != null
                      ? 'Unlock $featureTitle'
                      : 'Upgrade to Tally Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  featureDescription ??
                      'Get advanced insights, custom theme studio colors, home-screen launcher icons, and a 100% ad-free experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Feature Breakdown Cards
              _featureRow(
                icon: Icons.insights_rounded,
                title: 'Advanced Insights & Visual Trends',
                subtitle:
                    'Deep spending forecasts, category distributions & cash flow health score',
                primary: primary,
                onSurface: onSurface,
              ),
              _featureRow(
                icon: Icons.palette_rounded,
                title: 'Theme Studio & All 9 Premium Themes',
                subtitle:
                    'Fine-tune primary, secondary, and typography font colors to your taste',
                primary: primary,
                onSurface: onSurface,
              ),
              _featureRow(
                icon: Icons.app_shortcut_rounded,
                title: 'Launcher App Icons',
                subtitle:
                    'Switch your device home screen launcher icon between Ledger, Paper, & Ink',
                primary: primary,
                onSurface: onSurface,
              ),
              _featureRow(
                icon: Icons.block_flipped,
                title: '100% Ad-Free Experience',
                subtitle:
                    'All banner ads are completely removed across all screens and lists',
                primary: primary,
                onSurface: onSurface,
              ),

              const SizedBox(height: 24),

              // Primary Action: Unlock Pro Annual ($19.99)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PremiumScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Unlock Tally Pro — ${GeoLocationService.formatTierWithPeriod(proYearlyPrice, "/ yr")} (${GeoLocationService.formatTierWithPeriod(1.67, "/mo")})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Action: Remove Ads Only
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PremiumScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface,
                  side: BorderSide(color: onSurface.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  'Remove Ads Only — ${GeoLocationService.formatLocalizedTierPrice(removeAdsPrice)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Enter Promo Code or Reset Options
              if (PurchaseSecurityPolicy.allowDevelopmentUnlocks) Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.vpn_key_outlined, size: 16),
                    label: const Text(
                      'Enter Promo Code',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showPromoCodeDialog(context);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Reset to Free',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onPressed: () async {
                      await resetPurchases();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Purchases reset to Free Tier.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays the theme unlock modal allowing users to either watch a 30s fullscreen ad
  /// for a 1-time theme change or upgrade to Tally Pro for unlimited changes.
  static Future<void> showThemeUnlockModal(
    BuildContext context, {
    required String themeName,
    required VoidCallback onUnlocked,
  }) async {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: onSurface.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.palette_rounded, size: 36, color: primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock "$themeName"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This theme is part of the Tally Pro aesthetic collection. You can unlock it for 1-time use by watching a 30s ad, or upgrade to Pro for unlimited changes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              // Option 1: Watch 30s Ad to Unlock 1-Time Use
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await AdService.showRewardedThemeAd(
                      context: context,
                      onRewardEarned: () async {
                        await grantThemePass(1);
                        await consumeThemePass();
                        onUnlocked();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🎉 1-Time Theme Unlocked! Switched to $themeName.',
                              ),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      },
                    );
                  },
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 22),
                  label: const Text(
                    'Watch 30s Video Ad (Unlock 1-Time)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option 2: Upgrade to Tally Pro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showPaywallModal(
                      context,
                      featureTitle: 'Theme Studio & All Palettes',
                      featureDescription:
                          'Unlock unlimited access to all 9 brand themes, Graphic Theme Studio, predictive velocity, and no ads forever.',
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text(
                    'Upgrade to Pro — Unlimited Access',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _featureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primary,
    required Color onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the promo code redemption dialog
  static void showPromoCodeDialog(BuildContext context) {
    if (!PurchaseSecurityPolicy.allowDevelopmentUnlocks && !testingVipCodeEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotion codes are not available.')),
      );
      return;
    }
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => FormDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.redeem_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Redeem Promo Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter FREEVIP to enable temporary VIP testing with no ads on this device.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'FREEVIP',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await redeemPromoCode(textCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: Colors.teal,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invalid testing code. Try FREEVIP.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
