import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Centralized service providing single-source-of-truth application versioning.
///
/// Version is declared canonically in `pubspec.yaml` (e.g. `1.8.6+16`) and reflects
/// dynamically at runtime via [PackageInfo]. In unit tests or headless runners where
/// platform channels are unmocked, graceful fallback constants guarantee stability.
class AppVersion {
  AppVersion._();

  static const String fallbackVersion = '1.8.11';
  static const String fallbackBuildNumber = '21';
  static const String fallbackAppName = 'Tally';

  static String _version = fallbackVersion;
  static String _buildNumber = fallbackBuildNumber;
  static String _appName = fallbackAppName;
  static bool _initialized = false;

  /// Current semantic version (e.g., '1.8.6').
  static String get version => _version;

  /// Current build number (e.g., '16').
  static String get buildNumber => _buildNumber;

  /// Application brand name (e.g., 'Tally').
  static String get appName => _appName;

  /// Formatted user-facing display string (e.g., 'Tally v1.8.6 (Build 16)').
  static String get displayString => '$_appName v$_version (Build $_buildNumber)';

  /// Whether the service has resolved package info from the native platform.
  static bool get isInitialized => _initialized;

  /// Initializes package metadata from the native runtime.
  /// Safe to call multiple times and safe in test environments.
  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _version = info.version;
      }
      if (info.buildNumber.isNotEmpty) {
        _buildNumber = info.buildNumber;
      }
      if (info.appName.isNotEmpty) {
        _appName = info.appName;
      }
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppVersion] Platform channel unavailable, using fallback version $_version+$_buildNumber: $e');
      }
    }
  }

  /// Sets mock values for unit and widget testing.
  @visibleForTesting
  static void setMockValues({
    String? version,
    String? buildNumber,
    String? appName,
  }) {
    if (version != null) _version = version;
    if (buildNumber != null) _buildNumber = buildNumber;
    if (appName != null) _appName = appName;
    _initialized = true;
  }

  /// Resets back to fallback values.
  @visibleForTesting
  static void reset() {
    _version = fallbackVersion;
    _buildNumber = fallbackBuildNumber;
    _appName = fallbackAppName;
    _initialized = false;
  }
}
