import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/fullscreen_30sec_ad_dialog.dart';
import '../widgets/fullscreen_interstitial_ad_dialog.dart';
import 'monetization_service.dart';

/// Centralized Google Mobile Ads (AdMob) Integration Service.
///
/// Handles SDK initialization, official Google test ad unit IDs, authentic
/// Google Banner ads, Fullscreen Interstitial ads for tab transitions, and
/// official Rewarded Ads with a 30-second non-skippable player.
class AdService {
  AdService._();

  static bool _isInitialized = false;
  static RewardedAd? _rewardedAd;
  static bool _isLoadingRewardedAd = false;
  static InterstitialAd? _interstitialAd;
  static bool _isLoadingInterstitialAd = false;

  static bool _hasPerformedFirstTabSwitch = false;
  static int _tabSwitchesSinceLastAd = 0;
  static int _nextTabAdThreshold = 4; // Alternates between 4 and 5 tab switches

  /// Resets tab-switch ad tracking counters (used in testing and session resets).
  static void resetTabAdCountersForTesting() {
    _hasPerformedFirstTabSwitch = false;
    _tabSwitchesSinceLastAd = 0;
    _nextTabAdThreshold = 4;
  }

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

  /// Official Google AdMob Test Interstitial Ad Unit IDs (Screen / Tab Transitions)
  static String get interstitialAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      // Official Google Android test interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (!kIsWeb && Platform.isIOS) {
      // Official Google iOS test interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  /// Initializes the Google Mobile Ads SDK on supported platforms and preloads ads.
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
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService.initialize notice: $e');
    }
  }

  /// Preloads an official Google AdMob Interstitial Ad for seamless tab transitions.
  static void loadInterstitialAd() {
    if (!isSupportedPlatform || _isLoadingInterstitialAd || _interstitialAd != null) return;

    _isLoadingInterstitialAd = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isLoadingInterstitialAd = false;
          debugPrint('AdService: Google AdMob InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isLoadingInterstitialAd = false;
          debugPrint('AdService: Failed to load Google AdMob InterstitialAd: $error');
        },
      ),
    );
  }

  /// Displays a full-screen interstitial ad upon changing tabs for free users.
  /// Always triggers on the first tab switch, then triggers on every 4th to 5th tab switch.
  /// Pro & Ad-Free users bypass this immediately with 0 delay.
  static Future<void> showTabSwitchInterstitialAd({
    required BuildContext context,
    required VoidCallback onComplete,
  }) async {
    // Pro and Ad-Free subscribers never see transition ads
    if (MonetizationService.isAdFree) {
      onComplete();
      return;
    }

    bool shouldTriggerAd = false;
    if (!_hasPerformedFirstTabSwitch) {
      // Rule: ALWAYS trigger on first tab switch
      _hasPerformedFirstTabSwitch = true;
      _tabSwitchesSinceLastAd = 0;
      _nextTabAdThreshold = 4;
      shouldTriggerAd = true;
    } else {
      _tabSwitchesSinceLastAd++;
      if (_tabSwitchesSinceLastAd >= _nextTabAdThreshold) {
        shouldTriggerAd = true;
        _tabSwitchesSinceLastAd = 0;
        // Alternate threshold between 4 and 5 tab switches
        _nextTabAdThreshold = (_nextTabAdThreshold == 4) ? 5 : 4;
      }
    }

    if (!shouldTriggerAd) {
      onComplete();
      return;
    }

    // 1. If native Google AdMob InterstitialAd is preloaded on mobile, show it
    if (isSupportedPlatform && _interstitialAd != null) {
      final ad = _interstitialAd!;
      _interstitialAd = null; // Consume reference

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('AdService: InterstitialAd dismissed.');
          ad.dispose();
          loadInterstitialAd(); // Preload next
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('AdService: Failed to show InterstitialAd: $error');
          ad.dispose();
          loadInterstitialAd();
          onComplete();
        },
      );

      ad.show();
      return;
    }

    // 2. Cross-platform fallback: High-craft full-screen interstitial dialog
    if (context.mounted) {
      await FullscreenInterstitialAdDialog.show(
        context,
        onDismissed: onComplete,
      );
      loadInterstitialAd();
    } else {
      onComplete();
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
