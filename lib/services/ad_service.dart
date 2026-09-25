import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized Google Mobile Ads (AdMob) Integration Service.
///
/// Handles SDK initialization, test ad unit IDs, and creation of
/// authentic Google Banner ads for supported mobile platforms.
class AdService {
  AdService._();

  static bool _isInitialized = false;

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

  /// Initializes the Google Mobile Ads SDK on supported platforms.
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
    } catch (e) {
      debugPrint('AdService.initialize notice: $e');
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
