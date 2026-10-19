import 'package:flutter/material.dart';
import 'package:latyr_app/config/environment_config.dart';

/// Represents canonical brand presentation metadata.
/// All fields are dynamically resolvable from the server API payload.
class BrandToken {
  final String name;
  final Color brandColor;
  final Color tileColor;
  final Color? iconColor;
  final String? svgUrl;
  final String? logoUrl;
  final String? watchUrl;

  const BrandToken({
    required this.name,
    required this.brandColor,
    required this.tileColor,
    this.iconColor,
    this.svgUrl,
    this.logoUrl,
    this.watchUrl,
  });

  /// Robust hex color parser supporting #RGB, #RRGGBB, #AARRGGBB, and 0x formats.
  static Color colorFromHex(String? hexString, {Color fallback = const Color(0xFF1C1C1E)}) {
    if (hexString == null || hexString.trim().isEmpty) return fallback;
    var cleaned = hexString.trim().toUpperCase().replaceAll('#', '');
    if (cleaned.startsWith('0X')) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    } else if (cleaned.length == 3) {
      cleaned = 'FF${cleaned[0]}${cleaned[0]}${cleaned[1]}${cleaned[1]}${cleaned[2]}${cleaned[2]}';
    } else if (cleaned.length != 8) {
      return fallback;
    }
    final int? value = int.tryParse(cleaned, radix: 16);
    return value != null ? Color(value) : fallback;
  }
}

/// Centralized Brand Design Token Registry.
///
/// Implements the Server-Driven Dynamic Metadata pattern mandated by AGENTS.md.
/// UI widgets must NEVER contain hardcoded vendor hex colors or platform switch-cases.
/// They must resolve brand tokens via [BrandRegistry.resolve].
class BrandRegistry {
  BrandRegistry._();

  /// Resolves a [BrandToken] from server-provided provider map or fallback token.
  static BrandToken resolve({
    required String name,
    Map<String, dynamic>? serverMetadata,
    String? mediaTitle,
  }) {
    final cleanName = name.trim();

    // 1. Primary: Server-Driven Metadata from API payload
    if (serverMetadata != null) {
      final serverBrandHex = serverMetadata['brand_color']?.toString();
      final serverTileHex = serverMetadata['tile_color']?.toString() ?? serverBrandHex;
      final serverIconHex = serverMetadata['icon_color']?.toString();
      final serverSvgUrl = serverMetadata['svg_url']?.toString();
      final serverLogo = serverMetadata['logo_url']?.toString();
      final serverWatchUrl = serverMetadata['watch_url']?.toString() ?? serverMetadata['link']?.toString();

      if (serverTileHex != null && serverTileHex.isNotEmpty) {
        final fallback = _resolveFallback(cleanName, mediaTitle: mediaTitle);
        return BrandToken(
          name: cleanName,
          brandColor: BrandToken.colorFromHex(serverBrandHex, fallback: fallback.brandColor),
          tileColor: BrandToken.colorFromHex(serverTileHex, fallback: fallback.tileColor),
          iconColor: serverIconHex != null
              ? BrandToken.colorFromHex(serverIconHex, fallback: Colors.white)
              : fallback.iconColor,
          svgUrl: serverSvgUrl ?? fallback.svgUrl,
          logoUrl: serverLogo ?? fallback.logoUrl,
          watchUrl: serverWatchUrl ?? fallback.watchUrl,
        );
      }
    }

    // 2. Centralized Fallback: Canonical tokens for offline/standalone execution
    return _resolveFallback(cleanName, mediaTitle: mediaTitle);
  }

  static BrandToken _resolveFallback(String name, {String? mediaTitle}) {
    final lower = name.toLowerCase();
    final query = mediaTitle != null ? Uri.encodeComponent(mediaTitle) : '';
    final cdn = EnvironmentConfig.cdnBaseUrl;

    if (lower.contains('netflix')) {
      return BrandToken(
        name: 'Netflix',
        brandColor: const Color(0xFFE50914),
        tileColor: const Color(0xFF000000),
        iconColor: null,
        svgUrl: '${cdn}netflix.svg',
        watchUrl: query.isNotEmpty ? 'https://www.netflix.com/search?q=$query' : 'https://www.netflix.com',
      );
    }
    if (lower.contains('prime') || lower.contains('amazon')) {
      return BrandToken(
        name: 'Prime Video',
        brandColor: const Color(0xFF00A8E1),
        tileColor: const Color(0xFF00A8E1),
        iconColor: Colors.white,
        svgUrl: '${cdn}prime_video.svg',
        watchUrl: query.isNotEmpty ? 'https://www.amazon.com/s?k=$query&i=instant-video' : 'https://www.primevideo.com',
      );
    }
    if (lower.contains('apple')) {
      return BrandToken(
        name: 'Apple TV',
        brandColor: const Color(0xFF000000),
        tileColor: const Color(0xFF000000),
        iconColor: Colors.white,
        svgUrl: '${cdn}apple_tv.svg',
        watchUrl: query.isNotEmpty ? 'https://tv.apple.com/search?term=$query' : 'https://tv.apple.com',
      );
    }
    if (lower.contains('hotstar')) {
      return BrandToken(
        name: 'JioHotstar',
        brandColor: const Color(0xFF14805E),
        tileColor: const Color(0xFF0C111B),
        iconColor: null,
        svgUrl: '${cdn}hotstar.svg',
        watchUrl: query.isNotEmpty ? 'https://www.hotstar.com/in/explore?search_query=$query' : 'https://www.hotstar.com',
      );
    }
    if (lower.contains('disney')) {
      return BrandToken(
        name: 'Disney+',
        brandColor: const Color(0xFF040714),
        tileColor: const Color(0xFF040714),
        iconColor: null,
        svgUrl: '${cdn}disney_plus.svg',
        watchUrl: query.isNotEmpty ? 'https://www.disneyplus.com/search?q=$query' : 'https://www.disneyplus.com',
      );
    }
    if (lower.contains('max') || lower.contains('hbo')) {
      return BrandToken(
        name: 'Max',
        brandColor: const Color(0xFF002BE7),
        tileColor: const Color(0xFF002BE7),
        iconColor: Colors.white,
        svgUrl: '${cdn}hbo_max.svg',
        watchUrl: query.isNotEmpty ? 'https://play.max.com/search?q=$query' : 'https://play.max.com',
      );
    }
    if (lower.contains('hulu')) {
      return BrandToken(
        name: 'Hulu',
        brandColor: const Color(0xFF1CE783),
        tileColor: const Color(0xFF000000),
        iconColor: null,
        svgUrl: '${cdn}hulu.svg',
        watchUrl: query.isNotEmpty ? 'https://www.hulu.com/search?q=$query' : 'https://www.hulu.com',
      );
    }
    if (lower.contains('paramount')) {
      return BrandToken(
        name: 'Paramount+',
        brandColor: const Color(0xFF0064FF),
        tileColor: const Color(0xFF0064FF),
        iconColor: Colors.white,
        svgUrl: '${cdn}paramount_plus.svg',
        watchUrl: query.isNotEmpty ? 'https://www.paramountplus.com/search/?query=$query' : 'https://www.paramountplus.com',
      );
    }
    if (lower.contains('peacock')) {
      return BrandToken(
        name: 'Peacock',
        brandColor: const Color(0xFF000000),
        tileColor: const Color(0xFF000000),
        iconColor: null,
        svgUrl: '${cdn}peacock.svg',
        watchUrl: query.isNotEmpty ? 'https://www.peacocktv.com/search?q=$query' : 'https://www.peacocktv.com',
      );
    }
    if (lower.contains('youtube')) {
      return BrandToken(
        name: 'YouTube',
        brandColor: const Color(0xFFFF0000),
        tileColor: const Color(0xFFFFFFFF),
        iconColor: const Color(0xFFFF0000),
        svgUrl: '${cdn}youtube.svg',
        watchUrl: query.isNotEmpty ? 'https://www.youtube.com/results?search_query=$query' : 'https://www.youtube.com',
      );
    }

    // Default neutral token for regional / obscure providers
    return BrandToken(
      name: name,
      brandColor: const Color(0xFF1C1C1E),
      tileColor: const Color(0xFF1C1C1E),
      iconColor: null,
      watchUrl: query.isNotEmpty ? 'https://www.google.com/search?q=watch+$query' : null,
    );
  }
}
