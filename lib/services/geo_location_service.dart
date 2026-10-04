import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'state.dart';

/// Detects regional country, default currency, and preferred language from the user device's locale.
/// Also provides purchasing power parity (PPP) / regional pricing calculations so payment plans
/// dynamically adapt to the user's selected or detected currency (PKR, INR, EUR, GBP, USD, AED, SAR, etc.).
class GeoLocationService {
  GeoLocationService._();

  /// Detects the user's country code (e.g. 'PK', 'IN', 'US', 'GB', 'DE', 'AE', 'SA').
  static String get detectedCountryCode {
    try {
      final code = ui.PlatformDispatcher.instance.locale.countryCode;
      if (code != null && code.isNotEmpty) {
        return code.toUpperCase();
      }
    } catch (e) {
      debugPrint('GeoLocationService country detection notice: $e');
    }
    return 'US';
  }

  /// Detects the user's device language code (e.g. 'ur', 'ar', 'hi', 'es', 'fr', 'de', 'en').
  static String get detectedLanguageCode {
    try {
      final code = ui.PlatformDispatcher.instance.locale.languageCode;
      if (code.isNotEmpty) {
        return code.toLowerCase();
      }
    } catch (e) {
      debugPrint('GeoLocationService language detection notice: $e');
    }
    return 'en';
  }

  /// Maps detected country code to regional currency symbol.
  static String get detectedCurrencySymbol {
    final country = detectedCountryCode;
    switch (country) {
      case 'PK':
        return '₨'; // Pakistani Rupee
      case 'IN':
        return '₹'; // Indian Rupee
      case 'GB':
      case 'UK':
        return '£'; // British Pound
      case 'AE':
        return 'د.إ'; // UAE Dirham
      case 'SA':
        return '﷼'; // Saudi Riyal
      case 'CA':
        return 'C\$'; // Canadian Dollar
      case 'AU':
        return 'A\$'; // Australian Dollar
      case 'JP':
        return '¥'; // Japanese Yen
      // Eurozone countries:
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'BE':
      case 'AT':
      case 'PT':
      case 'IE':
      case 'FI':
      case 'GR':
        return '€';
      case 'US':
      default:
        return '\$';
    }
  }

  /// Resolves the best supported app language based on device locale.
  static String get detectedSupportedLanguage {
    final lang = detectedLanguageCode;
    const supported = {'en', 'es', 'fr', 'de', 'ur', 'ar', 'hi'};
    if (supported.contains(lang)) {
      return lang;
    }
    // Infer from country if language is English default on foreign device
    final country = detectedCountryCode;
    if (country == 'PK') return 'ur';
    if (country == 'SA' || country == 'AE') return 'ar';
    if (country == 'IN') return 'hi';
    if (country == 'ES' || country == 'MX' || country == 'AR' || country == 'CO') return 'es';
    if (country == 'FR') return 'fr';
    if (country == 'DE' || country == 'AT') return 'de';
    return 'en';
  }

  /// Converts a USD base tier price into regional currency with realistic formatting and purchasing power parity.
  static String formatLocalizedTierPrice(double usdPrice, [String? currency]) {
    final cur = currency ?? AppState.currencyNotifier.value;

    switch (cur) {
      case '₨': // PKR
        if (usdPrice >= 35.0) return '₨11,000';
        if (usdPrice >= 18.0) return '₨5,500';
        if (usdPrice >= 2.5) return '₨850';
        if (usdPrice >= 1.5) return '₨550';
        return '₨${(usdPrice * 280).toStringAsFixed(0)}';

      case '₹': // INR
        if (usdPrice >= 35.0) return '₹3,399';
        if (usdPrice >= 18.0) return '₹1,699';
        if (usdPrice >= 2.5) return '₹250';
        if (usdPrice >= 1.5) return '₹169';
        return '₹${(usdPrice * 85).toStringAsFixed(0)}';

      case '€': // EUR
        return '€${usdPrice.toStringAsFixed(2)}';

      case '£': // GBP
        if (usdPrice >= 35.0) return '£34.99';
        if (usdPrice >= 18.0) return '£16.99';
        if (usdPrice >= 2.5) return '£2.49';
        if (usdPrice >= 1.5) return '£1.69';
        return '£${(usdPrice * 0.8).toStringAsFixed(2)}';

      case 'د.إ': // AED
        if (usdPrice >= 35.0) return 'د.إ 150.00';
        if (usdPrice >= 18.0) return 'د.إ 75.00';
        if (usdPrice >= 2.5) return 'د.إ 11.99';
        if (usdPrice >= 1.5) return 'د.إ 7.50';
        return 'د.إ ${(usdPrice * 3.67).toStringAsFixed(2)}';

      case '﷼': // SAR
        if (usdPrice >= 35.0) return '﷼ 150.00';
        if (usdPrice >= 18.0) return '﷼ 75.00';
        if (usdPrice >= 2.5) return '﷼ 11.99';
        if (usdPrice >= 1.5) return '﷼ 7.50';
        return '﷼ ${(usdPrice * 3.75).toStringAsFixed(2)}';

      case 'C\$': // CAD
        if (usdPrice >= 35.0) return 'C\$54.99';
        if (usdPrice >= 18.0) return 'C\$26.99';
        if (usdPrice >= 2.5) return 'C\$3.99';
        if (usdPrice >= 1.5) return 'C\$2.69';
        return 'C\$${(usdPrice * 1.35).toStringAsFixed(2)}';

      case 'A\$': // AUD
        if (usdPrice >= 35.0) return 'A\$59.99';
        if (usdPrice >= 18.0) return 'A\$29.99';
        if (usdPrice >= 2.5) return 'A\$4.49';
        if (usdPrice >= 1.5) return 'A\$2.99';
        return 'A\$${(usdPrice * 1.5).toStringAsFixed(2)}';

      case '¥': // JPY
        if (usdPrice >= 35.0) return '¥5,980';
        if (usdPrice >= 18.0) return '¥2,980';
        if (usdPrice >= 2.5) return '¥450';
        if (usdPrice >= 1.5) return '¥300';
        return '¥${(usdPrice * 150).toStringAsFixed(0)}';

      case '\$':
      default:
        return '\$${usdPrice.toStringAsFixed(2)}';
    }
  }

  /// Formats tier price with recurring period suffix (e.g. "$19.99 / yr", "₨5,500 / yr").
  static String formatTierWithPeriod(double usdPrice, String periodSuffix, [String? currency]) {
    final priceStr = formatLocalizedTierPrice(usdPrice, currency);
    if (periodSuffix.isEmpty) return priceStr;
    return '$priceStr $periodSuffix';
  }
}
