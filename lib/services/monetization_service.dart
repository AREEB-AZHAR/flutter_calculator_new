import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonetizationService {
  static const String _prefProUnlockedKey = 'tally_pro_unlocked';
  static const String _prefAdsRemovedKey = 'tally_ads_removed';

  static final ValueNotifier<bool> isProUnlockedNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isAdsRemovedNotifier = ValueNotifier<bool>(false);

  /// True if user has purchased / unlocked Tally Pro (all-access).
  static bool get isPro => isProUnlockedNotifier.value;

  /// True if ads should be hidden (either via Pro unlock or dedicated Remove Ads purchase).
  static bool get isAdFree => isProUnlockedNotifier.value || isAdsRemovedNotifier.value;

  /// Initializes monetization states from local SharedPreferences.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isProUnlockedNotifier.value = prefs.getBool(_prefProUnlockedKey) ?? false;
      isAdsRemovedNotifier.value = prefs.getBool(_prefAdsRemovedKey) ?? false;
    } catch (e) {
      debugPrint('MonetizationService.initialize error: $e');
    }
  }

  /// Unlocks Tally Pro (access to Insights, Theme Studio, Launcher App Icons, and removes ads).
  static Future<void> unlockPro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefProUnlockedKey, true);
      isProUnlockedNotifier.value = true;
    } catch (e) {
      debugPrint('MonetizationService.unlockPro error: $e');
    }
  }

  /// Unlocks the separate Remove Ads option (removes banner ads without full Pro features).
  static Future<void> removeAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAdsRemovedKey, true);
      isAdsRemovedNotifier.value = true;
    } catch (e) {
      debugPrint('MonetizationService.removeAds error: $e');
    }
  }

  /// Resets all purchase and unlock flags to Free tier (ideal for testing and verification).
  static Future<void> resetPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefProUnlockedKey);
      await prefs.remove(_prefAdsRemovedKey);
      isProUnlockedNotifier.value = false;
      isAdsRemovedNotifier.value = false;
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
    } else if (code == 'RESET' || code == 'RESETVIP' || code == 'RESETPRO' || code == 'FREE' || code == 'FREEVIP') {
      await resetPurchases();
      return '🔄 VIP Subscription & Ad-Free status have been reset to Free tier.';
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
                icon: Icons.color_lens_rounded,
                title: 'Theme Studio (Custom Color Wheel)',
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

              // Primary Action: Unlock Pro Bundle
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
                    Text('Unlock Tally Pro — \$4.99 (One-Time)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Action: Remove Ads Only
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
              'Enter a VIP promo code to unlock Tally Pro or Ad-Free features for testing.',
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              decoration: InputDecoration(
                hintText: 'e.g. PROVIP, NOADS, or RESETVIP',
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
                    const SnackBar(content: Text('Invalid promo code. Try PROVIP, NOADS, or RESETVIP.'), backgroundColor: Colors.redAccent),
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
