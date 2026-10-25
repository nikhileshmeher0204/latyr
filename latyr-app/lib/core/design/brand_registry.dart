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
  final String? rawSvg;
  final String? logoUrl;
  final String? watchUrl;

  const BrandToken({
    required this.name,
    required this.brandColor,
    required this.tileColor,
    this.iconColor,
    this.svgUrl,
    this.rawSvg,
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
/// Official Google/YouTube 2017 Vector Icon with tight bounding box (viewBox="0 0 28.57 20").
/// Sourced from official Wikimedia Commons / Google Brand Assets with zero outer padding.
const String kOfficialYouTubeSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28.57 20" width="100%" height="100%">'
    '<path d="M27.9727 3.12324C27.6435 1.89323 26.6768 0.926623 25.4468 0.597366C23.2197 0 14.285 0 14.285 0C14.285 0 5.35042 0 3.12323 0.597366C1.89323 0.926623 0.926623 1.89323 0.597366 3.12324C0 5.35042 0 10 0 10C0 10 0 14.6496 0.597366 16.8768C0.926623 18.1068 1.89323 19.0734 3.12323 19.4026C5.35042 20 14.285 20 14.285 20C14.285 20 23.2197 20 25.4468 19.4026C26.6768 19.0734 27.6435 18.1068 27.9727 16.8768C28.5701 14.6496 28.5701 10 28.5701 10C28.5677 5.35042 27.9727 3.12324Z" fill="#FF0000"/>'
    '<path d="M11.4253 14.2854L18.8477 10.0004L11.4253 5.71533V14.2854Z" fill="#FFFFFF"/>'
    '</svg>';

class BrandRegistry {
  BrandRegistry._();

  /// Resolves a [BrandToken] from server-provided provider map or fallback token.
  static BrandToken resolve({
    required String name,
    Map<String, dynamic>? serverMetadata,
    String? mediaTitle,
  }) {
    final cleanName = name.trim();

    // YouTube Canonical Enforcement:
    // Always use the official #0F0F0F dark tile and untinted red/white SVG,
    // overriding any legacy #FFFFFF server metadata stored in older records.
    if (cleanName.toLowerCase().contains('youtube')) {
      final fallback = _resolveFallback(cleanName, mediaTitle: mediaTitle);
      final serverWatchUrl = serverMetadata?['watch_url']?.toString() ?? serverMetadata?['link']?.toString();
      return BrandToken(
        name: 'YouTube',
        brandColor: fallback.brandColor,
        tileColor: fallback.tileColor,
        iconColor: null,
        svgUrl: fallback.svgUrl,
        rawSvg: kOfficialYouTubeSvg,
        watchUrl: serverWatchUrl ?? fallback.watchUrl,
      );
    }

    // 1. Primary: Server-Driven Metadata from API payload
    if (serverMetadata != null) {
      final serverBrandHex = serverMetadata['brand_color']?.toString();
      final serverTileHex = serverMetadata['tile_color']?.toString() ?? serverBrandHex;
      final serverIconHex = serverMetadata['icon_color']?.toString();
      final serverSvgUrl = serverMetadata['svg_url']?.toString();
      final serverLogo = serverMetadata['logo_url']?.toString();
      final serverWatchUrl = serverMetadata['watch_url']?.toString() ?? serverMetadata['link']?.toString();

      final fallback = _resolveFallback(cleanName, mediaTitle: mediaTitle);
      var resolvedSvgUrl = serverSvgUrl ?? fallback.svgUrl;
      if (resolvedSvgUrl != null) {
        resolvedSvgUrl = resolvedSvgUrl.replaceFirst(
          RegExp(r'https?://(?:uat-assets\.latyr\.app|latyr-a5dfa\.web\.app)/assets/icons/streaming/'),
          EnvironmentConfig.cdnBaseUrl,
        );
      }

      if (serverTileHex != null && serverTileHex.isNotEmpty) {
        return BrandToken(
          name: cleanName,
          brandColor: BrandToken.colorFromHex(serverBrandHex, fallback: fallback.brandColor),
          tileColor: BrandToken.colorFromHex(serverTileHex, fallback: fallback.tileColor),
          iconColor: serverIconHex != null
              ? BrandToken.colorFromHex(serverIconHex, fallback: Colors.white)
              : fallback.iconColor,
          svgUrl: resolvedSvgUrl,
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
        tileColor: const Color(0xFF0F0F0F),
        iconColor: null,
        svgUrl: '${cdn}youtube.svg',
        rawSvg: kOfficialYouTubeSvg,
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
