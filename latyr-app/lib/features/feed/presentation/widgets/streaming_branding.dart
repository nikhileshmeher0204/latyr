import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latyr_app/core/design/brand_registry.dart';
import 'package:url_launcher/url_launcher.dart';

/// StreamingBrand
///
/// Encapsulates brand colors, action labels, badges, and URL resolution
/// for streaming platforms. Consumes centralized BrandRegistry tokens to ensure
/// zero inlined magic hex values or platform switch-cases in presentation code.
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
    Map<String, dynamic>? metadata,
  }) {
    final token = BrandRegistry.resolve(
      name: rawPlatform ?? 'Stream',
      serverMetadata: {
        'logo_url': ?logoUrl,
        ...?metadata,
      },
    );

    final isTv = mediaType?.toLowerCase() == 'tv';
    final verb = isTv ? 'Watch' : 'Watch';

    final isTheater = token.name.toLowerCase().contains('theater') ||
        token.name.toLowerCase().contains('cinema');
    final textColor = isTheater ? Colors.black : Colors.white;
    final actionLabel = isTheater ? 'In Theaters' : '$verb on ${token.name}';

    Widget fallbackIcon = const Icon(CupertinoIcons.play_arrow_solid, size: 12, color: Colors.white);
    if (isTheater) {
      fallbackIcon = const Icon(CupertinoIcons.tickets_fill, size: 14, color: Colors.black);
    }

    Widget resolvedIcon = fallbackIcon;
    if (token.svgUrl != null && token.svgUrl!.startsWith('http')) {
      debugPrint('[StreamingBranding] Loading CDN SVG: ${token.svgUrl}');
      resolvedIcon = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: token.tileColor,
          borderRadius: BorderRadius.circular(2.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(2.2),
            child: SvgPicture.network(
              token.svgUrl!,
              fit: BoxFit.contain,
              colorFilter: token.iconColor != null
                  ? ColorFilter.mode(token.iconColor!, BlendMode.srcIn)
                  : null,
              placeholderBuilder: (_) => Container(
                color: token.tileColor,
              ),
            ),
          ),
        ),
      );
    } else if (logoUrl != null && logoUrl.trim().isNotEmpty) {
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
              color: token.tileColor,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          errorWidget: (context, url, error) => fallbackIcon,
        ),
      );
    }

    return StreamingBrand(
      name: token.name,
      actionLabel: actionLabel,
      brandColor: token.brandColor,
      textColor: textColor,
      icon: resolvedIcon,
    );
  }

  static Future<void> launchStreamingOrSearch({
    required String? url,
    required String title,
    String? platform,
  }) async {
    final token = BrandRegistry.resolve(
      name: platform ?? '',
      mediaTitle: title,
    );

    String target;
    if (url != null &&
        url.isNotEmpty &&
        !url.contains('imdb.com') &&
        !url.contains('themoviedb.org')) {
      target = url;
    } else if (token.watchUrl != null && token.watchUrl!.isNotEmpty) {
      target = token.watchUrl!;
    } else {
      final encoded = Uri.encodeComponent(title);
      target = 'https://www.google.com/search?q=watch+$encoded';
    }

    debugPrint('[StreamingBranding] Launching streaming target: $target (platform: $platform, title: $title)');
    final uri = Uri.tryParse(target);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('[StreamingBranding] launchUrl externalApplication result: $launched for $uri');
        if (!launched) {
          final fallbackLaunched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          debugPrint('[StreamingBranding] launchUrl platformDefault fallback result: $fallbackLaunched for $uri');
        }
      } catch (e) {
        debugPrint('[StreamingBranding] Error launching $uri externally: $e. Falling back to platformDefault.');
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    }
  }
}
