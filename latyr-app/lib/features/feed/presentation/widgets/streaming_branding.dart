import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// StreamingBrand
///
/// Encapsulates brand colors, action labels, badges, and URL resolution
/// for major streaming platforms (Netflix, Prime Video, Apple TV, Hotstar, etc.)
class StreamingBrand {
  final String name;
  final String actionLabel;
  final Color brandColor;
  final Color textColor;
  final Widget icon;

  const StreamingBrand({
    required this.name,
    required this.actionLabel,
    required this.brandColor,
    required this.textColor,
    required this.icon,
  });

  static StreamingBrand resolve(
    String? rawPlatform, {
    String? mediaType,
    String? logoUrl,
  }) {
    final p = (rawPlatform ?? '').trim().toLowerCase();
    final isTv = mediaType?.toLowerCase() == 'tv';
    final verb = isTv ? 'Watch' : 'Watch';

    Color brandColor = const Color(0xFF2C2C2E);
    Color textColor = Colors.white;
    String name = 'Stream';
    String actionLabel = 'Watch Now';
    Widget fallbackIcon = const Icon(CupertinoIcons.play_arrow_solid, size: 12, color: Colors.white);

    if (p.contains('netflix')) {
      name = 'Netflix';
      actionLabel = '$verb on Netflix';
      brandColor = const Color(0xFFE50914);
      fallbackIcon = _buildNetflixIcon();
    } else if (p.contains('prime') || p.contains('amazon')) {
      name = 'Prime Video';
      actionLabel = 'Stream on Prime';
      brandColor = const Color(0xFF00A8E1);
      fallbackIcon = _buildPrimeIcon();
    } else if (p.contains('apple')) {
      name = 'Apple TV';
      actionLabel = '$verb on Apple TV';
      brandColor = const Color(0xFF2C2C2E);
      fallbackIcon = const Icon(CupertinoIcons.app_badge_fill, size: 14, color: Colors.white);
    } else if (p.contains('hotstar') || p.contains('disney')) {
      name = 'JioHotstar';
      actionLabel = '$verb on Hotstar';
      brandColor = const Color(0xFF14805E);
      fallbackIcon = _buildHotstarIcon();
    } else if (p.contains('sonyliv') || p.contains('sony')) {
      name = 'Sony LIV';
      actionLabel = '$verb on Sony LIV';
      brandColor = const Color(0xFF003399);
      fallbackIcon = const Icon(CupertinoIcons.play_circle_fill, size: 14, color: Colors.white);
    } else if (p.contains('zee')) {
      name = 'ZEE5';
      actionLabel = '$verb on ZEE5';
      brandColor = const Color(0xFF7B1FA2);
      fallbackIcon = const Icon(CupertinoIcons.play_circle_fill, size: 14, color: Colors.white);
    } else if (p.contains('theater') || p.contains('cinema')) {
      name = 'In Theaters';
      actionLabel = 'In Theaters';
      brandColor = const Color(0xFFD4AF37);
      textColor = Colors.black;
      fallbackIcon = const Icon(CupertinoIcons.tickets_fill, size: 14, color: Colors.black);
    }

    Widget resolvedIcon = fallbackIcon;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      resolvedIcon = ClipRRect(
        borderRadius: BorderRadius.circular(2.5),
        child: CachedNetworkImage(
          imageUrl: logoUrl.trim(),
          width: 14,
          height: 14,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) => Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          errorWidget: (context, url, error) => fallbackIcon,
        ),
      );
    }

    return StreamingBrand(
      name: name,
      actionLabel: actionLabel,
      brandColor: brandColor,
      textColor: textColor,
      icon: resolvedIcon,
    );
  }

  static Widget _buildNetflixIcon() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFE50914),
        borderRadius: BorderRadius.circular(2.5),
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  static Widget _buildPrimeIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.5),
      ),
      child: const Text(
        'prime',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF00A8E1),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          height: 1.0,
        ),
      ),
    );
  }

  static Widget _buildHotstarIcon() {
    return const Icon(CupertinoIcons.star_fill, size: 13, color: Color(0xFFFFD60A));
  }

  static Future<void> launchStreamingOrSearch({
    required String? url,
    required String title,
    String? platform,
  }) async {
    String? target = url;
    if (target == null || target.isEmpty) {
      final p = (platform ?? '').toLowerCase();
      final encoded = Uri.encodeComponent(title);
      if (p.contains('netflix')) {
        target = 'https://www.netflix.com/search?q=$encoded';
      } else if (p.contains('prime')) {
        target = 'https://www.amazon.com/s?k=$encoded&i=instant-video';
      } else if (p.contains('apple')) {
        target = 'https://tv.apple.com/search?term=$encoded';
      } else {
        target = 'https://www.google.com/search?q=watch+$encoded';
      }
    }
    final uri = Uri.tryParse(target);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
