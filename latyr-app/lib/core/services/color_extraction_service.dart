import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ColorExtractionService {
  static final Map<String, Color> _resolvedCache = {};
  static final Map<String, Future<Color>> _inFlightCache = {};

  /// Fast synchronous lookup for already-quantized images.
  static Color? getCachedColor(String? imagePathOrUrl, {required bool isDark}) {
    if (imagePathOrUrl == null || imagePathOrUrl.isEmpty) return null;
    final cacheKey = '${imagePathOrUrl}_${isDark ? "dark" : "light"}';
    return _resolvedCache[cacheKey];
  }

  /// Extracts dominant pastel/jewel tone from image using ColorScheme.fromImageProvider.
  static Future<Color> extractDominantColor(
    String? imagePathOrUrl, {
    required bool isDark,
    Color? fallback,
  }) async {
    final defaultColor = fallback ?? (isDark ? const Color(0xFF2A9D8F) : const Color(0xFF88D4C8));
    if (imagePathOrUrl == null || imagePathOrUrl.isEmpty) {
      return defaultColor;
    }

    final cacheKey = '${imagePathOrUrl}_${isDark ? "dark" : "light"}';
    if (_resolvedCache.containsKey(cacheKey)) {
      return _resolvedCache[cacheKey]!;
    }

    if (_inFlightCache.containsKey(cacheKey)) {
      return _inFlightCache[cacheKey]!;
    }

    final future = _performExtraction(imagePathOrUrl, isDark, defaultColor);
    _inFlightCache[cacheKey] = future;
    try {
      final color = await future;
      _resolvedCache[cacheKey] = color;
      return color;
    } finally {
      _inFlightCache.remove(cacheKey);
    }
  }

  static Future<Color> _performExtraction(
    String imagePathOrUrl,
    bool isDark,
    Color defaultColor,
  ) async {
    try {
      final ImageProvider imageProvider;
      if (imagePathOrUrl.startsWith('http://') || imagePathOrUrl.startsWith('https://')) {
        imageProvider = CachedNetworkImageProvider(imagePathOrUrl);
      } else if (imagePathOrUrl.startsWith('assets/')) {
        imageProvider = AssetImage(imagePathOrUrl);
      } else {
        imageProvider = FileImage(File(imagePathOrUrl));
      }

      final colorScheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: Brightness.light,
      );

      final seedColor = colorScheme.primary;
      final hsl = HSLColor.fromColor(seedColor);

      // Latyr Aesthetic Knobs:
      // Light mode: soft, clean pastel card backgrounds (lightness ~0.78, saturation ~0.65)
      // Dark mode: deep, rich jewel tones (lightness ~0.38, saturation ~0.75)
      final targetSaturation = isDark ? 0.75 : 0.65;
      final targetLightness = isDark ? 0.38 : 0.78;

      final boostedSaturation = hsl.saturation.clamp(targetSaturation, 0.92);

      return hsl
          .withSaturation(boostedSaturation)
          .withLightness(targetLightness)
          .toColor();
    } catch (e) {
      debugPrint("Error extracting color from $imagePathOrUrl: $e");
      return defaultColor;
    }
  }
}
