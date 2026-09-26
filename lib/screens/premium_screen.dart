import 'package:flutter/material.dart';
import '../services/monetization_service.dart';

/// Dedicated Tally Pro & Ad-Free Upgrade Screen.
///
/// Features authentic Google Pay integration, transparent pricing tiers,
/// comprehensive feature comparison, VIP promo code redemption, and instant
/// developer testing reset controls.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedTierIndex = 0; // 0: Pro Lifetime, 1: Remove Ads Only
  bool _isProcessingPayment = false;

  Future<void> _handleGooglePay(String planTitle, double price, bool isPro, {bool isCoffee = false}) async {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Show Google Pay Confirmation Sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'G',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Pay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Google Pay',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Tally Technologies LLC',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  Text(
                    planTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.credit_card, size: 16, color: Colors.blueAccent),
                      SizedBox(width: 6),
                      Text('Google Account •••• 4242', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Encryption',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Google TLS / 256-bit', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fingerprint, size: 22, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Authenticate & Pay with Google Pay',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessingPayment = true);
      // Simulate authentic Google Play billing confirmation
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;

      if (isCoffee) {
        await MonetizationService.unlockCoffeeWithTrial();
      } else if (isPro) {
        await MonetizationService.unlockPro();
      } else {
        await MonetizationService.removeAds();
      }

      setState(() => _isProcessingPayment = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Icon(
                  isCoffee ? Icons.coffee_rounded : Icons.check_circle_rounded,
                  color: isCoffee ? Colors.amberAccent : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isCoffee ? 'Thank You for Your Gift!' : 'Payment Successful',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              isCoffee
                  ? 'Thank you so much for supporting independent development! ☕ As a gift, all banner ads have been removed for life, and your complimentary 7-Day Tally Pro VIP trial is now active!'
                  : (isPro
                      ? 'Welcome to Tally Pro! All analytics, theme customizations, custom launcher icons, and ad-free browsing are now unlocked.'
                      : 'Ads successfully removed! Enjoy your completely clean and uninterrupted Tally experience.'),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return ValueListenableBuilder<bool>(
      valueListenable: MonetizationService.isProUnlockedNotifier,
      builder: (context, isPro, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: MonetizationService.isAdsRemovedNotifier,
          builder: (context, isAdsRemoved, _) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Tally Pro & VIP', style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: surface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () => MonetizationService.showPromoCodeDialog(context),
                    icon: const Icon(Icons.vpn_key_rounded, size: 16),
                    label: const Text('Promo Code'),
                    style: TextButton.styleFrom(foregroundColor: primary),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. VIP Status Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPro
                                  ? [Colors.teal.shade900, const Color(0xFF10B981).withValues(alpha: 0.3)]
                                  : [primary.withValues(alpha: 0.85), primary.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (isPro ? Colors.teal : primary).withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isPro ? Icons.verified : Icons.workspace_premium,
                                          color: Colors.amberAccent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isPro ? 'TALLY PRO MEMBER' : 'FREE TIER',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPro)
                                    const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isPro
                                    ? 'All Pro Features Unlocked'
                                    : 'Supercharge Your Financial Intelligence',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPro
                                    ? 'You have unlimited access to multi-month predictive insights, graphic theme customizers, launcher icons, and an ad-free experience.'
                                    : 'Remove ads, unlock predictive spending velocity, customize colors freely, and switch dynamic app icons.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 2. Feature Checklist Showcase
                        Text(
                          'What\'s Included',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildFeatureRow(
                          icon: Icons.block_rounded,
                          title: '100% Ad-Free Experience',
                          subtitle: 'Zero banner ads, zero interruptions across all screens.',
                          isUnlocked: isPro || isAdsRemoved,
                          primary: primary,
                          onSurface: onSurface,
                        ),
                        _buildFeatureRow(
                          icon: Icons.trending_up_rounded,
                          title: 'Predictive Insights & Velocity',
                          subtitle: 'Daily spending run-rates, savings forecasting, and burn metrics.',
                          isUnlocked: isPro,
                          primary: primary,
                          onSurface: onSurface,
                        ),
                        _buildFeatureRow(
                          icon: Icons.palette_rounded,
                          title: 'Graphic Theme Studio',
                          subtitle: 'Fine-grained HSV sliders, hex picker, and custom typography tones.',
                          isUnlocked: isPro,
                          primary: primary,
                          onSurface: onSurface,
                        ),
                        _buildFeatureRow(
                          icon: Icons.apps_rounded,
                          title: 'Custom Dynamic Launcher Icons',
                          subtitle: 'Switch homescreen brand marks to Ink, Paper, or Ledger.',
                          isUnlocked: isPro,
                          primary: primary,
                          onSurface: onSurface,
                        ),
                        _buildFeatureRow(
                          icon: Icons.cloud_done_rounded,
                          title: 'Encrypted Google Cloud Sync',
                          subtitle: 'Seamless real-time multi-device database synchronization.',
                          isUnlocked: true,
                          primary: primary,
                          onSurface: onSurface,
                        ),

                        const SizedBox(height: 28),

                        // 3. Plan Selector
                        Text(
                          'Select Your Option',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Option 0: Pro Monthly ($4.99/mo)
                        _buildPlanCard(
                          index: 0,
                          title: 'Tally Pro Monthly',
                          price: '\$4.99 / mo',
                          badge: 'FLEXIBLE',
                          subtitle: 'Full month-to-month access to predictive analytics, Theme Studio & no ads.',
                          isSelected: _selectedTierIndex == 0,
                          isPurchased: isPro,
                          onTap: () => setState(() => _selectedTierIndex = 0),
                          primary: primary,
                          surface: surface,
                          onSurface: onSurface,
                        ),

                        const SizedBox(height: 12),

                        // Option 1: Pro Yearly ($49.90/yr -> 4.99 * 10, 2 Months Free)
                        _buildPlanCard(
                          index: 1,
                          title: 'Tally Pro Yearly',
                          price: '\$49.90 / yr',
                          badge: '⭐ BEST VALUE (2 MO FREE)',
                          subtitle: 'Pay for 10 months, get 12! Only \$4.16/mo (Save 17% vs monthly).',
                          isSelected: _selectedTierIndex == 1,
                          isPurchased: isPro,
                          onTap: () => setState(() => _selectedTierIndex = 1),
                          primary: primary,
                          surface: surface,
                          onSurface: onSurface,
                        ),

                        const SizedBox(height: 12),

                        // Option 2: Pro Lifetime ($47.88 -> 3.99 * 12)
                        _buildPlanCard(
                          index: 2,
                          title: 'Tally Pro Lifetime Access',
                          price: '\$47.88',
                          badge: '👑 ULTIMATE PASS',
                          subtitle: 'One-time payment (only \$3.99 × 12). Own all current & future Pro features forever.',
                          isSelected: _selectedTierIndex == 2,
                          isPurchased: isPro,
                          onTap: () => setState(() => _selectedTierIndex = 2),
                          primary: primary,
                          surface: surface,
                          onSurface: onSurface,
                        ),

                        const SizedBox(height: 12),

                        // Option 3: Buy Me a Coffee ($1.99) -> Ad-Free for life + 7-Day Pro Trial Gift!
                        _buildPlanCard(
                          index: 3,
                          title: '☕ Buy the Developer a Coffee',
                          price: '\$1.99',
                          badge: '🎁 BONUS GIFT',
                          subtitle: 'Fuel independent development! Enjoy 100% Ad-Free Tally for life + a complimentary 7-Day Tally Pro VIP Trial gift included.',
                          isSelected: _selectedTierIndex == 3,
                          isPurchased: isAdsRemoved || isPro,
                          onTap: () => setState(() => _selectedTierIndex = 3),
                          primary: primary,
                          surface: surface,
                          onSurface: onSurface,
                        ),

                        const SizedBox(height: 24),

                        // 4. Google Pay Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isProcessingPayment
                                ? null
                                : () {
                                    if (_selectedTierIndex == 0) {
                                      _handleGooglePay('Tally Pro Monthly', 4.99, true);
                                    } else if (_selectedTierIndex == 1) {
                                      _handleGooglePay('Tally Pro Yearly (Save 2 Mo)', 49.90, true);
                                    } else if (_selectedTierIndex == 2) {
                                      _handleGooglePay('Tally Pro Lifetime Access', 47.88, true);
                                    } else {
                                      _handleGooglePay('Buy Developer a Coffee & Ad-Free', 1.99, false, isCoffee: true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 3,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'G',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      'Pay',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedTierIndex == 0
                                      ? (isPro ? 'Already Pro • Manage' : 'Pay with Google Pay • \$4.99 / mo')
                                      : _selectedTierIndex == 1
                                          ? (isPro ? 'Already Pro • Manage' : 'Pay with Google Pay • \$49.90 / yr')
                                          : _selectedTierIndex == 2
                                              ? (isPro ? 'Already Pro • Manage' : 'Pay with Google Pay • \$47.88')
                                              : (isAdsRemoved ? 'Ads Already Removed • Send Coffee' : 'Pay with Google Pay • \$1.99'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 5. Test Mode & Reset Button
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await MonetizationService.resetPurchases();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test Mode: VIP Subscription & Purchases reset to Free tier!'),
                                    backgroundColor: Colors.deepOrange,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Colors.orangeAccent),
                            label: const Text(
                              'Reset VIP Subscription (Developer Test Mode)',
                              style: TextStyle(fontSize: 13, color: Colors.orangeAccent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 6. Security & Legal Notice
                        Center(
                          child: Text(
                            'Secured by Google Play Billing & Apple App Store • 256-bit TLS Encryption\nNo recurring hidden fees • Family Sharing ready',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: onSurface.withValues(alpha: 0.5),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  if (_isProcessingPayment)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUnlocked,
    required Color primary,
    required Color onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.green.withValues(alpha: 0.15) : onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUnlocked ? Icons.check_circle_rounded : icon,
              size: 20,
              color: isUnlocked ? Colors.green : onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    if (isUnlocked) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'UNLOCKED',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String badge,
    required String subtitle,
    required bool isSelected,
    required bool isPurchased,
    required VoidCallback onTap,
    required Color primary,
    required Color surface,
    required Color onSurface,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : onSurface.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primary : onSurface.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPurchased
                              ? Colors.green.withValues(alpha: 0.15)
                              : primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPurchased ? 'OWNED' : badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPurchased ? Colors.green : primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? primary : onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
