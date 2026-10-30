import 'dart:io';
import 'package:flutter/material.dart';

/// Helper utility for managing profile images and network vs. local file resolution.
class ImageHelper {
  static final Map<String, bool> _fileExistenceCache = {};

  /// Checks whether [path] exists on disk, caching the result to avoid repeated synchronous I/O during builds.
  static bool cachedFileExists(String path) {
    return _fileExistenceCache.putIfAbsent(path, () {
      try {
        return File(path).existsSync();
      } catch (_) {
        return false;
      }
    });
  }

  /// Clears or invalidates a path from the file existence cache.
  static void invalidateCache([String? path]) {
    if (path == null) {
      _fileExistenceCache.clear();
    } else {
      _fileExistenceCache.remove(path);
    }
  }

  /// Checks whether [path] is a web/cloud network URL (http/https).
  static bool isNetworkImage(String? path) {
    if (path == null) return false;
    final trimmed = path.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Returns an [ImageProvider] for profile pictures, supporting both local filesystem
  /// paths and network URLs. Returns null if invalid or not found.
  static ImageProvider? getProfileImageProvider(String? photoPath, {String fallbackAsset = 'assets/images/default_avatar.png'}) {
    if (photoPath == null || photoPath.trim().isEmpty) {
      return AssetImage(fallbackAsset);
    }
    final path = photoPath.trim();
    if (isNetworkImage(path)) {
      return NetworkImage(path);
    }
    try {
      if (cachedFileExists(path)) {
        return FileImage(File(path));
      }
    } catch (_) {}
    return AssetImage(fallbackAsset);
  }
}

/// Top-level helper for existing call sites
ImageProvider? getProfileImageProvider(String? photoPath) {
  if (photoPath == null || photoPath.trim().isEmpty) return null;
  final path = photoPath.trim();
  if (ImageHelper.isNetworkImage(path)) {
    return NetworkImage(path);
  }
  try {
    if (ImageHelper.cachedFileExists(path)) {
      return FileImage(File(path));
    }
  } catch (_) {}
  return null;
}

