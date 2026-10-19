import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latyr_app/core/design/brand_registry.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/enums/watch_provider_category.dart';
import 'package:latyr_app/features/feed/presentation/widgets/streaming_branding.dart';

const String _fontFamily = 'Inter';

/// Represents a single resolved watch provider item.
class WatchProviderItem {
  final String name;
  final WatchProviderCategory category;
  final String? type; // 'stream', 'rent', 'buy', 'free'
  final String? logoUrl;
  final String? svgUrl;
  final String? watchUrl;
  final Color brandColor;
  final Color tileColor;
  final Color? iconColor;

  const WatchProviderItem({
    required this.name,
    this.category = WatchProviderCategory.subscription,
    this.type = 'stream',
    this.logoUrl,
    this.svgUrl,
    this.watchUrl,
    required this.brandColor,
    required this.tileColor,
    this.iconColor,
  });

  /// Factory resolving from dynamic server metadata or centralized registry.
  /// Zero hardcoded colors or brand switch-cases in this widget.
  factory WatchProviderItem.fromServerMap(
    Map<String, dynamic> providerMap, {
    WatchProviderCategory category = WatchProviderCategory.subscription,
    String? mediaTitle,
  }) {
    final name = (providerMap['provider_name'] ?? providerMap['name'] ?? '').toString();
    final token = BrandRegistry.resolve(
      name: name,
      serverMetadata: providerMap,
      mediaTitle: mediaTitle,
    );

    return WatchProviderItem(
      name: token.name,
      category: category,
      type: providerMap['type']?.toString() ?? 'stream',
      logoUrl: token.logoUrl,
      svgUrl: token.svgUrl,
      watchUrl: token.watchUrl,
      brandColor: token.brandColor,
      tileColor: token.tileColor,
      iconColor: token.iconColor,
    );
  }

  /// Fallback resolver for a standalone platform name string.
  factory WatchProviderItem.fromNameAndLogo(
    String rawName, {
    WatchProviderCategory category = WatchProviderCategory.subscription,
    String? logoUrl,
    String? type,
    String? watchUrl,
    String? mediaTitle,
    Map<String, dynamic>? extraMetadata,
  }) {
    final token = BrandRegistry.resolve(
      name: rawName,
      serverMetadata: {
        'logo_url': ?logoUrl,
        'watch_url': ?watchUrl,
        ...?extraMetadata,
      },
      mediaTitle: mediaTitle,
    );

    return WatchProviderItem(
      name: token.name,
      category: category,
      type: type ?? 'stream',
      logoUrl: token.logoUrl,
      svgUrl: token.svgUrl,
      watchUrl: token.watchUrl,
      brandColor: token.brandColor,
      tileColor: token.tileColor,
      iconColor: token.iconColor,
    );
  }
}

/// Backwards compatibility alias
typedef StreamingProviderItem = WatchProviderItem;

/// Dedicated, light-grey card displaying "Where to Watch" categorized by
/// Subscription, Rent, Buy, and Free with labels in-line with the platform logos.
class WhereToWatchCard extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final String title;
  final bool isDark;

  const WhereToWatchCard({
    super.key,
    required this.metadata,
    required this.title,
    required this.isDark,
  });

  Map<WatchProviderCategory, List<WatchProviderItem>> _resolveGroupedProviders() {
    final Map<WatchProviderCategory, List<WatchProviderItem>> grouped = {};
    for (final cat in WatchProviderCategory.values) {
      grouped[cat] = [];
    }
    final seenPerCategory = <WatchProviderCategory, Set<String>>{};
    final mediaTitle = metadata['title']?.toString() ?? title;

    // 1. Check metadata['watch_providers'] list (from TMDB / JustWatch / Server Enriched)
    final rawProviders = metadata['watch_providers'];
    if (rawProviders is List && rawProviders.isNotEmpty) {
      for (final p in rawProviders) {
        if (p is Map) {
          final pMap = Map<String, dynamic>.from(p);
          final pName = pMap['provider_name']?.toString() ?? pMap['name']?.toString() ?? '';
          final category = WatchProviderCategory.fromString(
            pMap['type']?.toString() ?? pMap['category']?.toString(),
          );
          final seen = seenPerCategory.putIfAbsent(category, () => <String>{});
          if (pName.isNotEmpty && seen.add(pName.toLowerCase())) {
            grouped[category]!.add(WatchProviderItem.fromServerMap(
              pMap,
              category: category,
              mediaTitle: mediaTitle,
            ));
          }
        }
      }
    }

    // 2. Fallback: single streaming_platform string
    final totalResolved = grouped.values.fold<int>(0, (sum, list) => sum + list.length);
    if (totalResolved == 0) {
      final singlePlatform = metadata['streaming_platform']?.toString();
      if (singlePlatform != null &&
          singlePlatform.isNotEmpty &&
          singlePlatform != 'In Theaters') {
        final category = WatchProviderCategory.fromString(metadata['type']?.toString());
        grouped[category]!.add(WatchProviderItem.fromNameAndLogo(
          singlePlatform,
          category: category,
          logoUrl: metadata['provider_logo_url']?.toString() ?? metadata['streaming_icon']?.toString(),
          watchUrl: metadata['watch_url']?.toString() ?? metadata['streaming_deep_link']?.toString(),
          mediaTitle: mediaTitle,
          extraMetadata: {
            if (metadata['streaming_brand_color'] != null) 'brand_color': metadata['streaming_brand_color'],
            if (metadata['streaming_tile_color'] != null) 'tile_color': metadata['streaming_tile_color'],
          },
        ));
      }
    }

    // Filter out categories with zero items
    return Map.fromEntries(
      grouped.entries.where((entry) => entry.value.isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _resolveGroupedProviders();
    if (grouped.isEmpty) return const SizedBox.shrink();

    final cardBg = LColors.lightGreyCard.resolveFrom(context);
    final cardBorder = LColors.lightGreyCardBorder.resolveFrom(context);
    final titleColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);
    final subheadColor = (isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F)).withValues(alpha: 0.7);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: TV Icon + "Where to Watch" (styled exactly like Capture Intents)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.tv,
                size: 14.5,
                color: titleColor,
              ),
              const SizedBox(width: 7),
              Text(
                'Where to Watch',
                style: TextStyle(
                  fontFamily: LTypography.roundedFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories: Subscription, Rent, Buy, Free (in-line with icons)
          for (int i = 0; i < grouped.entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildCategoryRow(
              category: grouped.entries.elementAt(i).key,
              items: grouped.entries.elementAt(i).value,
              subheadColor: subheadColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required WatchProviderCategory category,
    required List<WatchProviderItem> items,
    required Color subheadColor,
  }) {
    final hasMultipleRows = items.length > 4;

    return Row(
      crossAxisAlignment: hasMultipleRows ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Category Label on the same row as icons
        SizedBox(
          width: 92,
          child: Padding(
            padding: hasMultipleRows ? const EdgeInsets.only(top: 12) : EdgeInsets.zero,
            child: Text(
              category.label,
              style: TextStyle(
                fontFamily: LTypography.roundedFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: subheadColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Platform Logo Buttons
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: items.map((item) {
              return _WatchProviderLogoButton(
                item: item,
                title: title,
                metadata: metadata,
                isDark: isDark,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Backwards compatibility alias
typedef StreamingPlatformsCard = WhereToWatchCard;

/// Tactile, spring-animated logo button with deep link redirection.
class _WatchProviderLogoButton extends StatefulWidget {
  final WatchProviderItem item;
  final String title;
  final Map<String, dynamic> metadata;
  final bool isDark;

  const _WatchProviderLogoButton({
    required this.item,
    required this.title,
    required this.metadata,
    required this.isDark,
  });

  @override
  State<_WatchProviderLogoButton> createState() => _WatchProviderLogoButtonState();
}

class _WatchProviderLogoButtonState extends State<_WatchProviderLogoButton> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    final item = widget.item;
    final url = item.watchUrl ??
        widget.metadata['streaming_deep_link']?.toString() ??
        widget.metadata['watch_url']?.toString();

    await StreamingBrand.launchStreamingOrSearch(
      url: url,
      title: widget.title,
      platform: item.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double size = 44;

    return Semantics(
      button: true,
      label: 'Watch on ${widget.item.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: widget.item.tileColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: widget.isDark
                    ? CupertinoColors.white.withValues(alpha: 0.15)
                    : CupertinoColors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildLogoContent(size),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoContent(double size) {
    final item = widget.item;

    if (item.svgUrl != null && item.svgUrl!.startsWith('http')) {
      debugPrint('[WhereToWatchCard] Loading CDN SVG: ${item.svgUrl}');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.5),
          child: SvgPicture.network(
            item.svgUrl!,
            fit: BoxFit.contain,
            colorFilter: item.iconColor != null
                ? ColorFilter.mode(item.iconColor!, BlendMode.srcIn)
                : null,
            placeholderBuilder: (_) => _buildFallbackInitial(size),
          ),
        ),
      );
    }

    if (item.logoUrl != null && item.logoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _buildFallbackInitial(size),
      );
    }

    return _buildFallbackInitial(size);
  }

  Widget _buildFallbackInitial(double size) {
    final initial = widget.item.name.isNotEmpty
        ? widget.item.name[0].toUpperCase()
        : 'S';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: _fontFamily,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
