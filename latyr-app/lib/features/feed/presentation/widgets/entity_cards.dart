import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/widgets/latyr_expandable_text.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/screens/entity_detail_screen.dart';
import 'package:latyr_app/features/feed/presentation/screens/github_repo_detail_screen.dart';
import 'package:latyr_app/features/feed/presentation/widgets/github_language_colors.dart';
import 'package:latyr_app/features/feed/presentation/widgets/streaming_branding.dart';
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
    final ratingSource = entity.metadata['rating_source']?.toString() ?? 'IMDb';
    final imdbVotes = entity.metadata['imdb_votes']?.toString();
    final rottenTomatoes = entity.metadata['rotten_tomatoes_rating']?.toString();
    final contentRating = entity.metadata['content_rating']?.toString();
    final releaseYear = entity.metadata['release_year']?.toString();
    final runtime = entity.metadata['runtime_formatted']?.toString();
    final seasons = entity.metadata['seasons_formatted']?.toString();
    final tagline = entity.metadata['tagline']?.toString();
    final streamingPlatform = entity.metadata['streaming_platform']?.toString();
    final streamingDeepLink = entity.metadata['streaming_deep_link']?.toString();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    final isTv = (entity.metadata['media_type']?.toString().toLowerCase() == 'tv' ||
        entity.entityType.toUpperCase() == 'TV_SHOW');
    final formatLabel = isTv ? 'Series' : 'Movie';
    final durationOrSeasons = isTv ? seasons : runtime;

    final subtitleParts = [
      formatLabel,
      if (releaseYear != null && releaseYear.isNotEmpty) releaseYear,
      if (durationOrSeasons != null && durationOrSeasons.isNotEmpty) durationOrSeasons,
      if (contentRating != null && contentRating.isNotEmpty && contentRating != 'N/A') contentRating,
    ].join(' · ');

    final descriptionText = (entity.description != null && entity.description!.isNotEmpty)
        ? entity.description!
        : (tagline != null && tagline.isNotEmpty ? tagline : null);

    final providerLogoUrl = entity.metadata['provider_logo_url']?.toString() ??
        entity.metadata['streaming_icon']?.toString();

    final streamingBrand = StreamingBrand.resolve(
      streamingPlatform,
      mediaType: isTv ? 'tv' : 'movie',
      logoUrl: providerLogoUrl,
    );

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => EntityDetailScreen(entity: entity),
            ),
          );
        },
        child: _CardContainer(
          cardColor: cardColor,
          isEmbedded: isEmbedded,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2:3 Magazine Sized Poster
              Hero(
                tag: 'entity_poster_${entity.id ?? entity.title}',
                child: Container(
                  width: 90,
                  height: 135,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (posterUrl != null && posterUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: posterUrl,
                            width: 90,
                            height: 135,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 150),
                            fadeOutDuration: const Duration(milliseconds: 100),
                            memCacheWidth: 270,
                            placeholder: (context, url) => Container(
                              width: 90,
                              height: 135,
                              color: isDark ? const Color(0x33FFFFFF) : const Color(0x1A000000),
                              child: const Center(
                                child: CupertinoActivityIndicator(radius: 10),
                              ),
                            ),
                            errorWidget: (context, error, stack) => _buildPlaceholderPoster(isDark),
                          )
                        : _buildPlaceholderPoster(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entity.title,
                            style: TextStyle(
                              fontFamily: _roundedFontFamily,
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rating != null && rating.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _RatingSourceBadge(
                            rating: rating,
                            source: ratingSource,
                            votes: imdbVotes,
                            rottenTomatoes: rottenTomatoes,
                            title: entity.title,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleParts,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: textColor.withValues(alpha: 0.55),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (descriptionText != null && descriptionText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      LatyrExpandableText(
                        text: descriptionText,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          color: textColor.withValues(alpha: 0.75),
                          fontSize: 12,
                          height: 1.35,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _FlavoredStreamingCtaButton(
                        brand: streamingBrand,
                        title: entity.title,
                        url: streamingDeepLink ?? entity.externalUrl,
                        platform: streamingPlatform,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster(bool isDark) {
    return Container(
      width: 90,
      height: 135,
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33FFFFFF) : const Color(0x1A000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.film, color: Color(0xFFBF5AF2), size: 30),
      ),
    );
  }
}

class _RatingSourceBadge extends StatelessWidget {
  final String rating;
  final String source;
  final String? votes;
  final String? rottenTomatoes;
  final String? title;
  final bool isDark;

  const _RatingSourceBadge({
    required this.rating,
    required this.source,
    this.votes,
    this.rottenTomatoes,
    this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isImdb = source.toUpperCase() == 'IMDB';
    final accentColor = isImdb ? const Color(0xFFF5C518) : const Color(0xFF01B4E4);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (title != null) {
          _showRatingSheet(context, accentColor);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.22 : 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.55 : 0.38),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('★', style: TextStyle(color: Color(0xFFFFD60A), fontSize: 10.5)),
            const SizedBox(width: 3),
            Text(
              rating,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: isDark ? Colors.white : Colors.black,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              source,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: accentColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingSheet(BuildContext context, Color accentColor) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          title ?? 'Rating & Verification',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        message: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('★', style: TextStyle(color: Color(0xFFFFD60A), fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '$rating / 10 ($source)',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            if (votes != null && votes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '$votes global user ratings on IMDb',
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
            if (rottenTomatoes != null && rottenTomatoes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '🍅 Rotten Tomatoes: $rottenTomatoes Tomatometer',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Attribution: IMDb is a registered trademark of IMDb.com, Inc. Ratings are sourced from public entertainment databases under nominative fair use for identification.',
              style: TextStyle(fontSize: 10.5, color: CupertinoColors.systemGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ),
    );
  }
}


class _FlavoredStreamingCtaButton extends StatelessWidget {
  final StreamingBrand brand;
  final String title;
  final String? url;
  final String? platform;
  final bool isDark;

  const _FlavoredStreamingCtaButton({
    required this.brand,
    required this.title,
    required this.url,
    required this.platform,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        StreamingBrand.launchStreamingOrSearch(
          url: url,
          title: title,
          platform: platform,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: brand.brandColor.withValues(alpha: isDark ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: brand.brandColor.withValues(alpha: isDark ? 0.65 : 0.4),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            brand.icon,
            const SizedBox(width: 5),
            Text(
              brand.actionLabel,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.play_arrow_solid,
              size: 9,
              color: textColor.withValues(alpha: 0.75),
            ),
          ],
        ),
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
    final stars = entity.metadata['stars'];
    final forks = entity.metadata['forks'];
    final language = entity.metadata['language']?.toString();
    final avatarUrl = entity.metadata['owner_avatar_url']?.toString();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => GitHubRepoDetailScreen(entity: entity),
            ),
          );
        },
      child: _CardContainer(
        cardColor: cardColor,
        isEmbedded: isEmbedded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (avatarUrl != null && avatarUrl.isNotEmpty) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF21262D) : const Color(0xFFEAEEF2),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _buildDefaultSquare(),
                    ),
                  ),
                ] else ...[
                  _buildDefaultSquare(),
                ],
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
                          if (language != null && language.isNotEmpty) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: GitHubLanguageColors.resolve(language),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              language,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (stars != null) ...[
                            const Icon(CupertinoIcons.star_fill, size: 10, color: Color(0xFFE3B341)),
                            const SizedBox(width: 3),
                            Text(
                              GitHubLanguageColors.formatCount(stars),
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (forks != null) ...[
                            Icon(CupertinoIcons.arrow_branch, size: 10, color: textColor.withValues(alpha: 0.45)),
                            const SizedBox(width: 3),
                            Text(
                              GitHubLanguageColors.formatCount(forks),
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
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: textColor.withValues(alpha: 0.35),
                ),
              ],
            ),
            if (entity.description != null && entity.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              LatyrExpandableText(
                text: entity.description!,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: textColor.withValues(alpha: 0.72),
                  fontSize: 12,
                  height: 1.35,
                  letterSpacing: -0.1,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _CtaButton(
                ctaText: 'OPEN REPO',
                url: entity.externalUrl,
                icon: CupertinoIcons.arrow_up_right,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDefaultSquare() {
    return _buildIconSquare(
      icon: CupertinoIcons.chevron_left_slash_chevron_right,
      iconColor: const Color(0xFF64D2FF),
      bgColor: const Color(0xFF64D2FF).withValues(alpha: 0.15),
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
