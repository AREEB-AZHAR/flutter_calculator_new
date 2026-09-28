import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';

class MonetizationService {
  static const String _prefProUnlockedKey = 'tally_pro_unlocked';
  static const String _prefAdsRemovedKey = 'tally_ads_removed';
  static const String _prefProTrialExpiryKey = 'tally_pro_trial_expiry';
  static const String _prefThemePassesKey = 'tally_theme_passes';

  // Recalculated Pro Pricing Matrix (Fintech Benchmark & Unit Economics)
  static const double proMonthlyPrice = 2.99;
  static const double proYearlyPrice = 19.99; // $1.67/mo (Save 44%)
  static const double proLifetimePrice = 39.99; // 2x Annual, Lifetime Access
  static const double removeAdsPrice = 1.99; // Standalone banner ad removal
  static const double coffeeTipPrice = 2.99; // Tip jar + Ad-Free for life + 7-Day Pro trial

  static final ValueNotifier<bool> isProUnlockedNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isAdsRemovedNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<DateTime?> proTrialExpiryNotifier = ValueNotifier<DateTime?>(null);
  static final ValueNotifier<int> themePassesNotifier = ValueNotifier<int>(0);

  static String? _activeUsername;

  static String _userKey(String baseKey) {
    if (_activeUsername != null && _activeUsername!.isNotEmpty) {
      return '${baseKey}_$_activeUsername';
    }
    return baseKey;
  }

  /// True if user is currently enjoying an active 7-day promotional Pro trial.
  static bool get isTrialActive {
    final expiry = proTrialExpiryNotifier.value;
    return expiry != null && DateTime.now().isBefore(expiry);
  }

  /// Remaining trial days (or 0 if expired/not active).
  static int get trialDaysRemaining {
    final expiry = proTrialExpiryNotifier.value;
    if (expiry == null) return 0;
    final diff = expiry.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff + 1 : 0;
  }

  /// True if user has purchased / unlocked Tally Pro (all-access) or has an active trial.
  static bool get isPro => isProUnlockedNotifier.value || isTrialActive;

  /// True if ads should be hidden (either via Pro unlock, dedicated Remove Ads, or coffee gift).
  static bool get isAdFree => isProUnlockedNotifier.value || isAdsRemovedNotifier.value || isTrialActive;

  /// True if user has unlimited access via Pro or has at least 1 theme pass.
  static bool get hasThemePass => isPro || themePassesNotifier.value > 0;

  /// Initializes monetization states from local SharedPreferences.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isProUnlockedNotifier.value = prefs.getBool(_userKey(_prefProUnlockedKey)) ?? false;
      isAdsRemovedNotifier.value = prefs.getBool(_userKey(_prefAdsRemovedKey)) ?? false;
      themePassesNotifier.value = prefs.getInt(_userKey(_prefThemePassesKey)) ?? 0;

      final trialStr = prefs.getString(_userKey(_prefProTrialExpiryKey));
      if (trialStr != null && trialStr.isNotEmpty) {
        final expiry = DateTime.tryParse(trialStr);
        if (expiry != null && DateTime.now().isBefore(expiry)) {
          proTrialExpiryNotifier.value = expiry;
        } else {
          proTrialExpiryNotifier.value = null;
        }
      }
    } catch (e) {
      debugPrint('MonetizationService.initialize error: $e');
    }
  }

  /// Loads entitlements strictly scoped to the specified user account.
  static Future<void> loadUserEntitlements(String username) async {
    _activeUsername = username;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProKey = '${_prefProUnlockedKey}_$username';
      final userAdsKey = '${_prefAdsRemovedKey}_$username';
      final userTrialKey = '${_prefProTrialExpiryKey}_$username';
      final userPassesKey = '${_prefThemePassesKey}_$username';

      isProUnlockedNotifier.value = prefs.getBool(userProKey) ?? false;
      isAdsRemovedNotifier.value = prefs.getBool(userAdsKey) ?? false;
      themePassesNotifier.value = prefs.getInt(userPassesKey) ?? 0;

      final trialStr = prefs.getString(userTrialKey);
      if (trialStr != null && trialStr.isNotEmpty) {
        final expiry = DateTime.tryParse(trialStr);
        if (expiry != null && DateTime.now().isBefore(expiry)) {
          proTrialExpiryNotifier.value = expiry;
        } else {
          proTrialExpiryNotifier.value = null;
        }
      } else {
        proTrialExpiryNotifier.value = null;
      }
    } catch (e) {
      debugPrint('MonetizationService.loadUserEntitlements error: $e');
    }
  }

  /// Resets in-memory entitlement notifiers to factory/logged-out state.
  static void resetToLoggedOut() {
    _activeUsername = null;
    isProUnlockedNotifier.value = false;
    isAdsRemovedNotifier.value = false;
    proTrialExpiryNotifier.value = null;
    themePassesNotifier.value = 0;
  }

  /// Grants one or more 1-time theme change passes (e.g. earned by watching a 30s ad).
  static Future<void> grantThemePass([int count = 1]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newCount = themePassesNotifier.value + count;
      await prefs.setInt(_userKey(_prefThemePassesKey), newCount);
      themePassesNotifier.value = newCount;
      debugPrint('MonetizationService: Granted $count theme pass(es) for $_activeUsername. Total: $newCount');
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
      await prefs.setInt(_userKey(_prefThemePassesKey), newCount);
      themePassesNotifier.value = newCount;
      debugPrint('MonetizationService: Consumed 1 theme pass for $_activeUsername. Remaining: $newCount');
      return true;
    } catch (e) {
      debugPrint('MonetizationService.consumeThemePass error: $e');
      return false;
    }
  }

  /// Unlocks Tally Pro (access to Insights, Theme Studio, Launcher App Icons, and removes ads).
  static Future<void> unlockPro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey(_prefProUnlockedKey), true);
      isProUnlockedNotifier.value = true;
    } catch (e) {
      debugPrint('MonetizationService.unlockPro error: $e');
    }
  }

  /// Unlocks the separate Remove Ads option (removes banner ads permanently).
  static Future<void> removeAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey(_prefAdsRemovedKey), true);
      isAdsRemovedNotifier.value = true;
    } catch (e) {
      debugPrint('MonetizationService.removeAds error: $e');
    }
  }

  /// Unlocks the "Buy Me a Coffee" developer gift:
  /// Permanently removes all banner ads + gives a complimentary 7-day Tally Pro VIP trial!
  static Future<void> unlockCoffeeWithTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey(_prefAdsRemovedKey), true);
      isAdsRemovedNotifier.value = true;

      final expiry = DateTime.now().add(const Duration(days: 7));
      await prefs.setString(_userKey(_prefProTrialExpiryKey), expiry.toIso8601String());
      proTrialExpiryNotifier.value = expiry;
    } catch (e) {
      debugPrint('MonetizationService.unlockCoffeeWithTrial error: $e');
    }
  }

  /// Resets all purchase and unlock flags to Free tier (ideal for testing and verification).
  static Future<void> resetPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey(_prefProUnlockedKey));
      await prefs.remove(_userKey(_prefAdsRemovedKey));
      await prefs.remove(_userKey(_prefProTrialExpiryKey));
      await prefs.remove(_userKey(_prefThemePassesKey));
      // Also clear legacy keys
      await prefs.remove(_prefProUnlockedKey);
      await prefs.remove(_prefAdsRemovedKey);
      await prefs.remove(_prefProTrialExpiryKey);
      await prefs.remove(_prefThemePassesKey);
      isProUnlockedNotifier.value = false;
      isAdsRemovedNotifier.value = false;
      proTrialExpiryNotifier.value = null;
      themePassesNotifier.value = 0;
    } catch (e) {
      debugPrint('MonetizationService.resetPurchases error: $e');
    }
  }

  /// Validates and redeems promo codes for instant feature unlock or testing resets.
  static Future<String?> redeemPromoCode(String inputCode) async {
    final code = inputCode.trim().toUpperCase();
    if (code == 'PROVIP' || code == 'TALLYPRO' || code == 'FINTECH2026' || code == 'UNLOCKALL') {
      await unlockPro();
      return '🎉 Tally Pro fully unlocked! All features & ad-free experience activated.';
    } else if (code == 'NOADS' || code == 'REMOVEADS' || code == 'ADFREE') {
      await removeAds();
      return '✨ Ads removed successfully! Enjoy clean banner-free budgeting.';
    } else if (code == 'THEMEPASS' || code == 'FREEPASS' || code == 'THEME3') {
      await grantThemePass(3);
      return '🎨 3 Free Theme Change Passes added to your vault!';
    } else if (code == 'RESET' || code == 'RESETVIP' || code == 'RESETPRO' || code == 'FREE' || code == 'FREEVIP') {
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
                  child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  featureTitle != null ? 'Unlock $featureTitle' : 'Upgrade to Tally Pro',
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
                  style: TextStyle(fontSize: 13, height: 1.4, color: onSurface.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 20),

              // Feature Breakdown Cards
              _featureRow(
                icon: Icons.insights_rounded,
                title: 'Advanced Insights & Visual Trends',
                subtitle: 'Deep spending forecasts, category distributions & cash flow health score',
                primary: primary,
                onSurface: onSurface,
              ),
              _featureRow(
                icon: Icons.palette_rounded,
                title: 'Theme Studio & All 9 Premium Themes',
                subtitle: 'Fine-tune primary, secondary, and typography font colors to your taste',
                primary: primary,
                onSurface: onSurface,
              ),
              _featureRow(
                icon: Icons.app_shortcut_rounded,
                title: 'Launcher App Icons',
                subtitle: 'Switch your device home screen launcher icon between Ledger, Paper, & Ink',
                primary: primary,
                onSurface: onSurface,
              ),
              _featureRow(
                icon: Icons.block_flipped,
                title: '100% Ad-Free Experience',
                subtitle: 'All banner ads are completely removed across all screens and lists',
                primary: primary,
                onSurface: onSurface,
              ),

              const SizedBox(height: 24),

              // Primary Action: Unlock Pro Annual ($19.99)
              ElevatedButton(
                onPressed: () async {
                  await unlockPro();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Tally Pro Unlocked! All features and ad-free experience are active.'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Unlock Tally Pro — \$19.99 / yr (\$1.67/mo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Action: Remove Ads Only ($1.99)
              OutlinedButton(
                onPressed: () async {
                  await removeAds();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✨ Ads Removed! Banner ads are now hidden.'),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface,
                  side: BorderSide(color: onSurface.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Remove Ads Only — \$1.99', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),

              const SizedBox(height: 12),

              // Enter Promo Code or Reset Options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.vpn_key_outlined, size: 16),
                    label: const Text('Enter Promo Code', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showPromoCodeDialog(context);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset to Free', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    onPressed: () async {
                      await resetPurchases();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchases reset to Free Tier.')),
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
                              content: Text('🎉 1-Time Theme Unlocked! Switched to $themeName.'),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      featureDescription: 'Unlock unlimited access to all 9 brand themes, Graphic Theme Studio, predictive velocity, and no ads forever.',
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text(
                    'Upgrade to Pro — Unlimited Access',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: onSurface)),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: onSurface.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the promo code redemption dialog
  static void showPromoCodeDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.redeem_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Redeem Promo Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a VIP promo code to unlock Tally Pro, Free Theme Passes, or Ad-Free features for testing.',
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              decoration: InputDecoration(
                hintText: 'e.g. PROVIP, THEMEPASS, NOADS',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await redeemPromoCode(textCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result), backgroundColor: Colors.teal),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid promo code. Try PROVIP, THEMEPASS, NOADS, or RESETVIP.'), backgroundColor: Colors.redAccent),
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
