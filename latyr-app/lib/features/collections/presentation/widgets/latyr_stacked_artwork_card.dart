import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/collections/domain/user_collection_model.dart';

class LatyrStackedArtworkCard extends StatelessWidget {
  final UserCollectionModel collection;
  final VoidCallback onTap;

  const LatyrStackedArtworkCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  Color _parseColor(String? hex, bool isDark) {
    if (hex != null && hex.isNotEmpty) {
      try {
        final clean = hex.replaceAll('#', '');
        final intVal = int.parse(clean, radix: 16);
        return Color(clean.length == 6 ? 0xFF000000 | intVal : intVal);
      } catch (_) {}
    }
    return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
  }

  IconData _parseIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'film':
      case 'movie':
        return CupertinoIcons.film;
      case 'tv':
      case 'series':
        return CupertinoIcons.tv;
      case 'code':
      case 'dev':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'book':
      case 'learn':
        return CupertinoIcons.book;
      case 'heart':
      case 'favorite':
        return CupertinoIcons.heart_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'folder':
      default:
        return CupertinoIcons.folder_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.6)
        : const Color(0xFF8E8E93);
    final accentColor = _parseColor(collection.colorHex, isDark);
    final posters = collection.previewArtworkUrls;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Stacked Poster Container
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth * 0.88;
                final cardHeight = constraints.maxHeight * 0.90;

                if (posters.isEmpty) {
                  return Center(
                    child: _buildEmptyPlaceholder(
                      width: cardWidth,
                      height: cardHeight,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                  );
                }

                return Center(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Layer 3: Back Poster (tilted -5.7 degrees)
                        if (posters.length >= 3)
                          Transform.translate(
                            offset: const Offset(-8, -6),
                            child: Transform.rotate(
                              angle: -0.10,
                              child: _buildPosterLayer(
                                url: posters[2],
                                width: cardWidth * 0.92,
                                height: cardHeight * 0.92,
                                opacity: 0.70,
                                isDark: isDark,
                              ),
                            ),
                          ),

                        // Layer 2: Middle Poster (tilted +4.6 degrees)
                        if (posters.length >= 2)
                          Transform.translate(
                            offset: const Offset(8, -3),
                            child: Transform.rotate(
                              angle: 0.08,
                              child: _buildPosterLayer(
                                url: posters[1],
                                width: cardWidth * 0.96,
                                height: cardHeight * 0.96,
                                opacity: 0.88,
                                isDark: isDark,
                              ),
                            ),
                          ),

                        // Layer 1: Front Poster (Upright 0 degrees)
                        _buildPosterLayer(
                          url: posters[0],
                          width: cardWidth,
                          height: cardHeight,
                          opacity: 1.0,
                          isDark: isDark,
                          showBorder: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: LSpacing.xs),

          // Collection Title
          Text(
            collection.name,
            style: LTypography.footnoteSemibold.rounded.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Item Count Badge
          Text(
            collection.itemCount == 1 ? '1 item' : '${collection.itemCount} items',
            style: LTypography.caption2.rounded.copyWith(
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterLayer({
    required String url,
    required double width,
    required double height,
    required double opacity,
    required bool isDark,
    bool showBorder = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: showBorder
            ? Border.all(
                color: isDark ? const Color(0x33FFFFFF) : const Color(0x18000000),
                width: 0.8,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: opacity,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, _) => Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              child: Icon(
                CupertinoIcons.photo,
                color: isDark ? CupertinoColors.systemGrey : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder({
    required double width,
    required double height,
    required Color accentColor,
    required bool isDark,
  }) {
    final bgColor = isDark
        ? const Color(0xFF1C1C1E)
        : CupertinoColors.white;
    final borderColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _parseIcon(collection.icon),
            color: accentColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
