import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/screens/entertainment_detail_screen.dart';
import 'package:latyr_app/features/feed/presentation/screens/github_repo_detail_screen.dart';
import 'package:latyr_app/features/feed/presentation/widgets/github_language_colors.dart';

const String _fontFamily = 'Inter';
const String _roundedFontFamily = 'InterRounded';

class EntityCardRouter extends StatelessWidget {
  final ExtractedEntityModel entity;
  final Color? cardColor;
  final bool isEmbedded;
  final String? categoryTitle;

  const EntityCardRouter({
    super.key,
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
    this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    switch (entity.entityType.toUpperCase()) {
      case 'MOVIE':
      case 'TV_SHOW':
        return _MovieShowCard(
          entity: entity,
          cardColor: cardColor,
          isEmbedded: isEmbedded,
          categoryTitle: categoryTitle,
        );
      case 'GITHUB_REPO':
        return _GitHubRepoCard(
          entity: entity,
          cardColor: cardColor,
          isEmbedded: isEmbedded,
          categoryTitle: categoryTitle,
        );
      case 'QUOTE':
        return _QuoteCard(entity: entity, cardColor: cardColor, isEmbedded: isEmbedded);
      default:
        return _GenericCard(
          entity: entity,
          cardColor: cardColor,
          isEmbedded: isEmbedded,
          categoryTitle: categoryTitle,
        );
    }
  }
}

class _MovieShowCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  final Color? cardColor;
  final bool isEmbedded;
  final String? categoryTitle;

  const _MovieShowCard({
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
    this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final movie = entity.entertainment;
    final posterUrl = movie.posterUrl;
    final rating = movie.rating;
    final ratingSource = movie.ratingSource;
    final imdbVotes = movie.imdbVotes;
    final rottenTomatoes = movie.rottenTomatoesRating;
    final contentRating = movie.contentRating;
    final releaseYear = movie.releaseYear;
    final tagline = movie.tagline;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    final isTv = movie.isTv;
    final formatLabel = isTv ? 'Series' : 'Movie';
    final durationOrSeasons = movie.durationOrSeasons;

    final metadataElements = [
      if (releaseYear != null && releaseYear.isNotEmpty) releaseYear,
      if (durationOrSeasons != null && durationOrSeasons.isNotEmpty) durationOrSeasons,
      if (contentRating != null && contentRating.isNotEmpty && contentRating != 'N/A') contentRating,
    ];
    if (metadataElements.isEmpty) {
      metadataElements.add(formatLabel);
    }
    final subtitleParts = metadataElements.join(' \u00B7 ');

    final descriptionText = (entity.description != null && entity.description!.isNotEmpty)
        ? entity.description!
        : (tagline != null && tagline.isNotEmpty ? tagline : null);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => EntertainmentDetailScreen(
                entity: entity,
                categoryTitle: categoryTitle,
              ),
            ),
          );
        },
        child: _CardContainer(
          cardColor: cardColor,
          isEmbedded: isEmbedded,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2:3 Magazine Sized Poster (Unmodified studio artwork for legal & trademark compliance)
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
                child: Container(
                  constraints: const BoxConstraints(minHeight: 135),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
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
                          if ((rating != null && rating.isNotEmpty) || subtitleParts.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (rating != null && rating.isNotEmpty) ...[
                                  _RatingSourceBadge(
                                    rating: rating,
                                    source: ratingSource,
                                    votes: imdbVotes,
                                    rottenTomatoes: rottenTomatoes,
                                    title: entity.title,
                                    isDark: isDark,
                                  ),
                                ],
                                if (subtitleParts.isNotEmpty) ...[
                                  if (rating != null && rating.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      child: Text(
                                        '\u00B7',
                                        style: TextStyle(
                                          color: textColor.withValues(alpha: 0.40),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
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
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (descriptionText != null && descriptionText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              descriptionText,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                color: textColor.withValues(alpha: 0.72),
                                fontSize: 12,
                                height: 1.35,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _OpenIntentButton(
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => EntertainmentDetailScreen(entity: entity),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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
    final textColor = isDark ? Colors.white : Colors.black;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.6,
      onPressed: () {
        if (title != null) {
          _showRatingSheet(context, const Color(0xFFF5C518));
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.star_fill,
            size: 11,
            color: Color(0xFFFFD60A),
          ),
          const SizedBox(width: 3),
          Text(
            rating,
            style: TextStyle(
              fontFamily: _fontFamily,
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          if (isImdb)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C518),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'IMDb',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.black,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  height: 1.0,
                ),
              ),
            )
          else
            Text(
              source,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: textColor.withValues(alpha: 0.6),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
        ],
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
                const Icon(CupertinoIcons.star_fill, color: Color(0xFFFFD60A), size: 18),
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
                '\u{1F345} Rotten Tomatoes: $rottenTomatoes Tomatometer',
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

class _OpenIntentButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _OpenIntentButton({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.60,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Open',
              style: TextStyle(
                fontFamily: _fontFamily,
                color: textColor.withValues(alpha: 0.90),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.15,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 3.5),
            Icon(
              CupertinoIcons.chevron_right,
              size: 9.5,
              color: textColor.withValues(alpha: 0.50),
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
  final String? categoryTitle;
  
  const _GitHubRepoCard({
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
    this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final repo = entity.gitHubRepo;
    final stars = repo.stars;
    final forks = repo.forks;
    final language = repo.language;
    final avatarUrl = repo.ownerAvatarUrl;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => GitHubRepoDetailScreen(
                entity: entity,
                categoryTitle: categoryTitle,
              ),
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
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
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161B22) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: borderColor,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/icons/github_mark.svg',
                            width: 10,
                            height: 10,
                            colorFilter: ColorFilter.mode(
                              isDark ? Colors.white : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                          if (language.isNotEmpty) ...[
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
              ],
            ),
            if (entity.description != null && entity.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entity.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: textColor.withValues(alpha: 0.72),
                  fontSize: 12,
                  height: 1.35,
                  letterSpacing: -0.1,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _OpenIntentButton(
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => GitHubRepoDetailScreen(
                        entity: entity,
                        categoryTitle: categoryTitle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDefaultSquare() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF24292F),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/github_mark.svg',
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
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
    final quote = entity.quote;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final authorOrSource = quote.author ?? entity.description;

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
                  '\u201C${quote.quoteText.isNotEmpty ? quote.quoteText : entity.title}\u201D',
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
          if (authorOrSource != null && authorOrSource.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                '\u2014 $authorOrSource',
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
  final String? categoryTitle;
  
  const _GenericCard({
    required this.entity,
    this.cardColor,
    this.isEmbedded = false,
    this.categoryTitle,
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _OpenIntentButton(
              isDark: isDark,
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => EntertainmentDetailScreen(
                      entity: entity,
                      categoryTitle: categoryTitle,
                    ),
                  ),
                );
              },
            ),
          ),
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
