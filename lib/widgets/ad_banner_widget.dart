import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/monetization_service.dart';
import '../services/ad_service.dart';

enum AdBannerSize {
  standard, // 320x50
  large, // 320x100
  mediumRectangle, // 300x250
}

class AdBannerWidget extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  final String? sponsorCategory;
  final AdBannerSize size;

  const AdBannerWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.sponsorCategory,
    this.size = AdBannerSize.large,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> with AutomaticKeepAliveClientMixin {
  // Preserve the native ad while a lazy scroll section is offscreen. Recreating
  // it on every return would reload the ad and churn platform views.
  @override
  bool get wantKeepAlive => true;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  AdSize get _adSize {
    switch (widget.size) {
      case AdBannerSize.standard:
        return AdSize.banner;
      case AdBannerSize.large:
        return AdSize.largeBanner;
      case AdBannerSize.mediumRectangle:
        return AdSize.mediumRectangle;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGoogleAd();
  }

  void _loadGoogleAd() {
    if (MonetizationService.isAdFree) return;
    if (!AdService.isSupportedPlatform) return;

    _bannerAd = AdService.createBannerAd(
      size: _adSize,
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('AdBannerWidget failed to load Google Ad: ${error.message}');
        ad.dispose();
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
          });
        }
      },
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<bool>(
      valueListenable: MonetizationService.isProUnlockedNotifier,
      builder: (context, isPro, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: MonetizationService.isAdsRemovedNotifier,
          builder: (context, isAdsRemoved, _) {
            // When user has unlocked Pro or Remove Ads, completely hide banner
            if (isPro || isAdsRemoved) {
              return const SizedBox.shrink();
            }

            final theme = Theme.of(context);
            final surface = theme.colorScheme.surface;
            final onSurface = theme.colorScheme.onSurface;
            final primary = theme.colorScheme.primary;

            // 1. If Google Mobile Ads banner is loaded, show authentic Google Ad
            if (_isAdLoaded && _bannerAd != null) {
              return RepaintBoundary(
                child: Container(
                  margin: widget.margin,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Text(
                                'Google Mobile Ads',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => MonetizationService.showPaywallModal(
                              context,
                              featureTitle: 'Ad-Free Tally',
                              featureDescription: 'Remove all Google banner advertisements permanently with a single tap.',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'Remove Ads',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ],
                ),
              ),
            );
          }

            // 2. Fallback sponsored banner (for Desktop/Windows or while loading)
            final isLarge = widget.size != AdBannerSize.standard;

            return RepaintBoundary(
              child: Container(
                margin: widget.margin,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLarge ? 16 : 10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: onSurface.withValues(alpha: 0.14), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: isLarge ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: isLarge ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                      children: [
                        // Ad Badge & Brand Icon
                        Container(
                          width: isLarge ? 48 : 38,
                          height: isLarge ? 48 : 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary.withValues(alpha: 0.2), primary.withValues(alpha: 0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primary.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Icon(Icons.campaign_rounded, size: isLarge ? 26 : 20, color: primary),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Sponsor Copy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'Ad • Partner',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.sponsorCategory ?? 'Google Cloud for Startups',
                                      style: TextStyle(
                                        fontSize: isLarge ? 13.5 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLarge
                                    ? 'Scale your financial infrastructure with \$350 startup credits, high-availability Cloud SQL, and automatic backup nodes.'
                                    : 'Scale your financial ledger with \$300 credits & secure cloud infrastructure.',
                                style: TextStyle(
                                  fontSize: isLarge ? 11.5 : 10.5,
                                  height: 1.35,
                                  color: onSurface.withValues(alpha: 0.7),
                                ),
                                maxLines: isLarge ? 2 : 1,
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
