import 'package:flutter/material.dart';
import '../services/monetization_service.dart';

class AdBannerWidget extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  final String? sponsorCategory;

  const AdBannerWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.sponsorCategory,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MonetizationService.isProUnlockedNotifier,
      builder: (context, isPro, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: MonetizationService.isAdsRemovedNotifier,
          builder: (context, isAdsRemoved, _) {
            // When user has unlocked Pro or Remove Ads, completely remove banner
            if (isPro || isAdsRemoved) {
              return const SizedBox.shrink();
            }

            final theme = Theme.of(context);
            final surface = theme.colorScheme.surface;
            final onSurface = theme.colorScheme.onSurface;
            final primary = theme.colorScheme.primary;

            return Container(
              margin: margin,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: onSurface.withValues(alpha: 0.12), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ad Badge & Brand Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(Icons.campaign_rounded, size: 20, color: primary),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Sponsor Copy
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Ad',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sponsorCategory ?? 'Google Cloud for Startups',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Scale your financial ledger with \$300 credits & secure cloud infrastructure.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: onSurface.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Remove Ads Shortcut Button
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => MonetizationService.showPaywallModal(
                      context,
                      featureTitle: 'Ad-Free Tally',
                      featureDescription: 'Remove all banner advertisements permanently with a single tap.',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Hide',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
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
}
