import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/fullscreen_30sec_ad_dialog.dart';

/// Centralized Google Mobile Ads (AdMob) Integration Service.
///
/// Handles SDK initialization, official Google test ad unit IDs, authentic
/// Google Banner ads, and official Rewarded Ads with a 30-second non-skippable
/// fullscreen player for unlocking 1-time theme changes.
class AdService {
  AdService._();

  static bool _isInitialized = false;
  static RewardedAd? _rewardedAd;
  static bool _isLoadingRewardedAd = false;

  /// True if Google Mobile Ads is supported on the current platform (Android / iOS).
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Official Google AdMob Test Banner Ad Unit IDs
  static String get bannerAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      // Official Google Android test banner ad unit ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (!kIsWeb && Platform.isIOS) {
      // Official Google iOS test banner ad unit ID
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  /// Official Google AdMob Test Rewarded Ad Unit IDs
  static String get rewardedAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      // Official Google Android test rewarded video ad unit ID
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (!kIsWeb && Platform.isIOS) {
      // Official Google iOS test rewarded video ad unit ID
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  /// Initializes the Google Mobile Ads SDK on supported platforms and preloads rewarded ads.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (!isSupportedPlatform) {
      debugPrint('AdService: Google Mobile Ads skipped on non-mobile platform (${kIsWeb ? "web" : Platform.operatingSystem})');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdService: Google Mobile Ads SDK initialized successfully.');
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdService.initialize notice: $e');
    }
  }

  /// Preloads an official Google AdMob Rewarded Ad.
  static void loadRewardedAd() {
    if (!isSupportedPlatform || _isLoadingRewardedAd || _rewardedAd != null) return;

    _isLoadingRewardedAd = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoadingRewardedAd = false;
          debugPrint('AdService: Google AdMob RewardedAd loaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isLoadingRewardedAd = false;
          debugPrint('AdService: Failed to load Google AdMob RewardedAd: $error');
        },
      ),
    );
  }

  /// Shows a non-skippable 30-second fullscreen ad to unlock a 1-time theme change.
  ///
  /// If the Google AdMob RewardedAd is loaded on a mobile device, displays the
  /// authentic Google video ad (which enforces completion to earn the reward).
  /// If running on desktop/web, or if Google Mobile Ads is unavailable/offline,
  /// displays the high-craft [Fullscreen30SecAdDialog] with an unskippable
  /// 30-second countdown timer and exit warning modal.
  static Future<void> showRewardedThemeAd({
    required BuildContext context,
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissed,
  }) async {
    if (isSupportedPlatform && _rewardedAd != null) {
      final ad = _rewardedAd!;
      _rewardedAd = null; // Consume reference

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('AdService: RewardedAd showed full screen content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('AdService: RewardedAd dismissed.');
          ad.dispose();
          loadRewardedAd(); // Preload next
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('AdService: Failed to show RewardedAd: $error');
          ad.dispose();
          loadRewardedAd();
          // Fall back to high-fidelity 30-second dialog
          if (context.mounted) {
            Fullscreen30SecAdDialog.show(
              context,
              onRewardEarned: onRewardEarned,
              onAdDismissed: onAdDismissed,
            );
          }
        },
      );

      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('AdService: User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
        },
      );
      return;
    }

    // Fallback: Fullscreen 30-Second Non-Skippable Ad Player (universal cross-platform)
    if (context.mounted) {
      await Fullscreen30SecAdDialog.show(
        context,
        onRewardEarned: onRewardEarned,
        onAdDismissed: onAdDismissed,
      );
      // Attempt background reload for subsequent requests
      loadRewardedAd();
    }
  }

  /// Creates and loads an authentic Google Mobile Ads BannerAd.
  static BannerAd? createBannerAd({
    required void Function(Ad ad) onAdLoaded,
    required void Function(Ad ad, LoadAdError error) onAdFailedToLoad,
    AdSize size = AdSize.banner,
  }) {
    if (!isSupportedPlatform) return null;

    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) => debugPrint('AdService: Banner ad opened.'),
        onAdClosed: (ad) => debugPrint('AdService: Banner ad closed.'),
      ),
    );
  }
}
