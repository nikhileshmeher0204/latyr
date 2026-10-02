import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DominantPalette {
  final Color background; // Dark ambient tone for SoftEdgeBlur and background gradients
  final Color accent;     // Vibrant luminous tone for highlights
  final Color subtle;     // Translucent tinted overlay
  final Color titleColor;
  final Color subtitleColor;
  final Color separatorColor;

  const DominantPalette({
    required this.background,
    required this.accent,
    required this.subtle,
    required this.titleColor,
    required this.subtitleColor,
    required this.separatorColor,
  });

  static final DominantPalette fallback = DominantPalette(
    background: const Color(0xFF141824),
    accent: const Color(0xFF9EC2FF),
    subtle: const Color(0x339EC2FF),
    titleColor: const Color(0xFFF5F9FF).withValues(alpha: 0.96),
    subtitleColor: const Color(0xFFEAF2FF).withValues(alpha: 0.88),
    separatorColor: const Color(0xFFEAF2FF).withValues(alpha: 0.55),
  );
}

class DominantColorService {
  DominantColorService._();
  static final DominantColorService instance = DominantColorService._();

  final Map<String, Future<DominantPalette>> _paletteCache = {};
  final Map<String, DominantPalette> _resolvedPalettes = {};

  DominantPalette? getCachedPalette(String? imagePathOrUrl) {
    if (imagePathOrUrl == null || imagePathOrUrl.isEmpty) return null;
    return _resolvedPalettes[imagePathOrUrl];
  }

  void warmUp(Iterable<String?> urls) {
    for (final url in urls) {
      if (url != null && url.isNotEmpty && !_resolvedPalettes.containsKey(url)) {
        extractPalette(url);
      }
    }
  }

  Future<DominantPalette> extractPalette(String? imagePathOrUrl) {
    if (imagePathOrUrl == null || imagePathOrUrl.isEmpty) {
      return Future.value(DominantPalette.fallback);
    }

    if (_resolvedPalettes.containsKey(imagePathOrUrl)) {
      return Future.value(_resolvedPalettes[imagePathOrUrl]!);
    }

    if (_paletteCache.containsKey(imagePathOrUrl)) {
      return _paletteCache[imagePathOrUrl]!;
    }

    final future = _performColorExtraction(imagePathOrUrl).then((palette) {
      _resolvedPalettes[imagePathOrUrl] = palette;
      return palette;
    });
    _paletteCache[imagePathOrUrl] = future;
    return future;
  }

  Future<Color> extractDominantColor(String? imagePathOrUrl) async {
    final cached = getCachedPalette(imagePathOrUrl);
    if (cached != null) return cached.background;
    final palette = await extractPalette(imagePathOrUrl);
    return palette.background;
  }

  Future<DominantPalette> _performColorExtraction(String imagePathOrUrl) async {
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

      // Apple TV dark vivid ambiance
      const double targetLightness = 0.18; // 0.15–0.22
      const double targetSaturation = 0.85; // 0.65–0.85

      final seedColor = colorScheme.primary;
      final hsl = HSLColor.fromColor(seedColor);
      final boostedSaturation = hsl.saturation.clamp(targetSaturation, 1.0);

      final darkBackground = hsl
          .withSaturation(boostedSaturation)
          .withLightness(targetLightness)
          .toColor();

      // Extract luminous accent color
      final accent = hsl
          .withSaturation(boostedSaturation.clamp(0.70, 0.95))
          .withLightness(0.74)
          .toColor();

      // Optical vibrancy colors based on background temperature
      final titleColor = getTitleColor(darkBackground);
      final subtitleColor = getSubtitleColor(darkBackground);
      final separatorColor = getSeparatorColor(darkBackground);

      return DominantPalette(
        background: darkBackground,
        accent: accent,
        subtle: accent.withValues(alpha: 0.2),
        titleColor: titleColor,
        subtitleColor: subtitleColor,
        separatorColor: separatorColor,
      );
    } catch (e) {
      debugPrint('[DominantColorService] Color extraction failed for $imagePathOrUrl: $e');
      return DominantPalette.fallback;
    }
  }

  static Color getTitleColor(Color bg) {
    final luminance = bg.computeLuminance();
    if (luminance < 0.45) {
      final isWarm = bg.r > bg.b;
      return isWarm
          ? const Color(0xFFFFFAF5).withValues(alpha: 0.96) // warm white
          : const Color(0xFFF5F9FF).withValues(alpha: 0.96); // cool white
    }
    return const Color(0xFF111111).withValues(alpha: 0.90);
  }

  static Color getSubtitleColor(Color bg) {
    final luminance = bg.computeLuminance();
    if (luminance < 0.45) {
      final isWarm = bg.r > bg.b;
      if (isWarm) {
        return const Color(0xFFFFF1E6).withValues(alpha: 0.90); // warm cream
      } else {
        return const Color(0xFFEAF2FF).withValues(alpha: 0.88); // cool ice white
      }
    }
    return const Color(0xFF1A1A1A).withValues(alpha: 0.75);
  }

  static Color getSeparatorColor(Color bg) {
    return getSubtitleColor(bg).withValues(alpha: 0.55);
  }
}
