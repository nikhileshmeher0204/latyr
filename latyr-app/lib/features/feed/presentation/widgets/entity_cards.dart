import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:url_launcher/url_launcher.dart';

const String _fontFamily = 'Inter';
const String _roundedFontFamily = 'InterRounded';

class EntityCardRouter extends StatelessWidget {
  final ExtractedEntityModel entity;
  final Color? cardColor;
  final bool isEmbedded;

  const EntityCardRouter({
    super.key,
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (entity.entityType.toUpperCase()) {
      case 'MOVIE':
      case 'TV_SHOW':
        return _MovieShowCard(entity: entity, cardColor: cardColor, isEmbedded: isEmbedded);
      case 'GITHUB_REPO':
        return _GitHubRepoCard(entity: entity, cardColor: cardColor, isEmbedded: isEmbedded);
      case 'QUOTE':
        return _QuoteCard(entity: entity, cardColor: cardColor, isEmbedded: isEmbedded);
      default:
        return _GenericCard(entity: entity, cardColor: cardColor, isEmbedded: isEmbedded);
    }
  }
}

class _MovieShowCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  final Color? cardColor;
  final bool isEmbedded;
  
  const _MovieShowCard({
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final posterUrl = entity.metadata['poster_url']?.toString();
    final rating = entity.metadata['rating']?.toString();
    final releaseYear = entity.metadata['release_year']?.toString();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return _CardContainer(
      cardColor: cardColor,
      isEmbedded: isEmbedded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (posterUrl != null && posterUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                posterUrl,
                width: 54,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _buildPlaceholderPoster(isDark),
              ),
            )
          else
            _buildPlaceholderPoster(isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entity.title,
                        style: TextStyle(
                          fontFamily: _roundedFontFamily,
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 6),
                      _PillBadge(label: rating, emoji: '\u2605', textColor: textColor, isDark: isDark),
                    ],
                  ],
                ),
                if (releaseYear != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    releaseYear,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
                if (entity.description != null && entity.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entity.description!,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: textColor.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.35,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CtaButton(
                    ctaText: 'WATCH',
                    url: entity.externalUrl,
                    icon: CupertinoIcons.play_arrow_solid,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPoster(bool isDark) {
    return Container(
      width: 54,
      height: 76,
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33FFFFFF) : const Color(0x1A000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.film, color: Color(0xFFBF5AF2), size: 24),
      ),
    );
  }
}

class _GitHubRepoCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  final Color? cardColor;
  final bool isEmbedded;
  
  const _GitHubRepoCard({
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final stars = entity.metadata['stars']?.toString();
    final language = entity.metadata['language']?.toString();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return _CardContainer(
      cardColor: cardColor,
      isEmbedded: isEmbedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconSquare(
                icon: CupertinoIcons.chevron_left_slash_chevron_right,
                iconColor: const Color(0xFF64D2FF),
                bgColor: const Color(0xFF64D2FF).withValues(alpha: 0.15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      style: TextStyle(
                        fontFamily: _roundedFontFamily,
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (stars != null) ...[
                          Icon(CupertinoIcons.star_fill, size: 10, color: textColor.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            stars,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 11,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (language != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD60A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            language,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 11,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entity.description!,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: textColor.withValues(alpha: 0.72),
                fontSize: 12,
                height: 1.35,
                letterSpacing: -0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _CtaButton(
              ctaText: 'VIEW REPO',
              url: entity.externalUrl,
              icon: CupertinoIcons.arrow_up_right,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  final Color? cardColor;
  final bool isEmbedded;
  
  const _QuoteCard({
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return _CardContainer(
      cardColor: cardColor,
      isEmbedded: isEmbedded,
      borderColor: LColors.brandAmber.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconSquare(
                icon: CupertinoIcons.quote_bubble_fill,
                iconColor: LColors.brandAmber,
                bgColor: LColors.brandAmber.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '\u201C${entity.title}\u201D',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: textColor,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                '\u2014 ${entity.description}',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenericCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  final Color? cardColor;
  final bool isEmbedded;
  
  const _GenericCard({
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final typeInfo = _resolveTypeInfo(entity.entityType);

    return _CardContainer(
      cardColor: cardColor,
      isEmbedded: isEmbedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconSquare(
                icon: typeInfo.icon,
                iconColor: typeInfo.color,
                bgColor: typeInfo.color.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      style: TextStyle(
                        fontFamily: _roundedFontFamily,
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entity.entityType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entity.entityType,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: typeInfo.color.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entity.description!,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: textColor.withValues(alpha: 0.72),
                fontSize: 12,
                height: 1.35,
                letterSpacing: -0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (entity.externalUrl != null && entity.externalUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _CtaButton(
                ctaText: 'OPEN',
                url: entity.externalUrl,
                icon: CupertinoIcons.arrow_right,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _buildIconSquare({required IconData icon, required Color iconColor, required Color bgColor}) {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Icon(icon, color: iconColor, size: 16),
    ),
  );
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? cardColor;
  final bool isEmbedded;

  const _CardContainer({
    required this.child,
    this.borderColor,
    this.cardColor,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmbedded) {
      return child;
    }
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    
    // Fallback if no card color provided
    final fallbackColor = isDark ? const Color(0x1A000000) : CupertinoColors.white.withValues(alpha: 0.4);
    
    // We apply border style matching home UI if cardColor is provided
    final hasCardColor = cardColor != null;
    final bColor = hasCardColor 
        ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white)
        : (borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor ?? fallbackColor,
        borderRadius: BorderRadius.circular(hasCardColor ? 24 : 14),
        border: Border.all(
          color: bColor,
          width: hasCardColor ? 2.5 : 0.8,
        ),
        boxShadow: hasCardColor ? [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: child,
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String ctaText;
  final String? url;
  final IconData icon;
  final bool isDark;

  const _CtaButton({
    required this.ctaText,
    required this.url,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () async {
        if (url != null && url!.isNotEmpty) {
          final uri = Uri.tryParse(url!);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctaText,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 10, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final String emoji;
  final Color textColor;
  final bool isDark;

  const _PillBadge({required this.label, required this.emoji, required this.textColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontFamily: _fontFamily, fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: _fontFamily,
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeInfo {
  final IconData icon;
  final Color color;
  _TypeInfo(this.icon, this.color);
}

_TypeInfo _resolveTypeInfo(String type) {
  switch (type.toUpperCase()) {
    case 'PLACE':
    case 'LOCATION':
      return _TypeInfo(CupertinoIcons.map_pin_ellipse, const Color(0xFF32ADE6));
    case 'PRODUCT':
      return _TypeInfo(CupertinoIcons.bag_fill, const Color(0xFFFF9F0A));
    case 'RECIPE':
    case 'FOOD':
      return _TypeInfo(CupertinoIcons.flame_fill, const Color(0xFFFF453A));
    case 'PERSON':
    case 'CREATOR':
      return _TypeInfo(CupertinoIcons.person_crop_circle_fill, const Color(0xFFBF5AF2));
    case 'ARTICLE':
    case 'BLOG':
      return _TypeInfo(CupertinoIcons.doc_text_fill, const Color(0xFF30D158));
    case 'TOOL':
    case 'APP':
      return _TypeInfo(CupertinoIcons.wrench_fill, const Color(0xFF0A84FF));
    case 'IDEA':
    case 'CONCEPT':
      return _TypeInfo(CupertinoIcons.lightbulb_fill, const Color(0xFFFFD60A));
    default:
      return _TypeInfo(CupertinoIcons.sparkles, const Color(0xFF64D2FF));
  }
}
