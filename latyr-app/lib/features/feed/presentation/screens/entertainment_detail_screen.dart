import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/widgets/intent_detail_app_bar.dart';
import 'package:latyr_app/features/feed/presentation/widgets/where_to_watch_card.dart';
import 'package:url_launcher/url_launcher.dart';

const String _fontFamily = 'Inter';
const String _roundedFontFamily = 'InterRounded';

/// EntertainmentDetailScreen
///
/// Apple TV-inspired editorial full-screen hero presentation for extracted entertainment media intents (Movies & TV Shows).
/// Displays a high-res portrait poster extending down through the title, synopsis,
/// and bottoming out just below the ratings row.
/// Employs Latyr's progressive blur shader with color vibrancy, and renders
/// translucent, luminous typography with subtle depth shadows without container boxes.
class EntertainmentDetailScreen extends StatelessWidget {
  final ExtractedEntityModel entity;

  const EntertainmentDetailScreen({
    super.key,
    required this.entity,
  });

  @override
  Widget build(BuildContext context) {
    final movie = entity.entertainment;
    final heroImage = movie.heroImage;
    final rating = movie.rating;
    final ratingSource = movie.ratingSource;
    final imdbVotes = movie.imdbVotes;
    final rottenTomatoes = movie.rottenTomatoesRating;
    final metascore = movie.metascoreRating;
    final contentRating = movie.contentRating;
    final awards = movie.awards;
    final writers = movie.writers;
    final country = movie.country;
    final language = movie.language;
    final releasedDate = movie.releasedDate;
    final boxOffice = movie.boxOffice;
    final releaseYear = movie.releaseYear;
    final tagline = movie.tagline;
    final overview = movie.overview ?? '';
    final imdbId = movie.imdbId;
    final director = movie.director;
    final leadCast = movie.leadCast;
    final genres = movie.genres;
    final isTv = movie.isTv;
    final formatLabel = movie.formatLabel;
    final durationOrSeasons = movie.durationOrSeasons;

    // Dynamic system theming: smoothly adapts between light and dark mode,
    // while preserving a rich black-tinted progressive blur on the hero poster.
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final scaffoldBgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final pageTextColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);
    final pageSubtextColor = isDark ? const Color(0xFF98989D) : const Color(0xFF86868B);

    // The hero typography sits on top of the black-tinted progressive blur,
    // ensuring luminous, razor-sharp legibility over the theatrical artwork.
    const heroIsDark = true;

    final screenH = MediaQuery.of(context).size.height;
    // Top breathing space so the actor's face / key artwork shines clearly before text begins
    final topArtSpacing = (screenH * 0.35).clamp(270.0, 360.0);

    // Subtitle string: "Movie · Crime · Drama" (No containers)
    final subtitleItems = <String>[];
    subtitleItems.add(formatLabel);
    if (genres.isNotEmpty) {
      subtitleItems.addAll(genres.take(3));
    }
    final subtitleString = subtitleItems.join(' · ');

    // Metrics items: ★ IMDb 🍅 RT [Metascore] Year · Runtime [Rating] (Apple TV compact row)
    final metricWidgets = <Widget>[];
    if (rating != null && rating.isNotEmpty) {
      metricWidgets.add(_RatingText(
        rating: rating,
        source: ratingSource,
        votes: imdbVotes,
        rottenTomatoes: rottenTomatoes,
        metascore: metascore,
        title: entity.title,
        isDark: heroIsDark,
      ));
    }
    if (rottenTomatoes != null && rottenTomatoes.isNotEmpty) {
      metricWidgets.add(_RottenTomatoesText(score: rottenTomatoes, isDark: heroIsDark));
    }
    if (metascore != null && metascore.isNotEmpty && metascore != 'N/A') {
      metricWidgets.add(_MetascoreText(score: metascore, isDark: heroIsDark));
    }
    final hasYear = releaseYear != null && releaseYear.isNotEmpty;
    final hasDuration = durationOrSeasons != null && durationOrSeasons.isNotEmpty;
    if (hasYear && hasDuration) {
      metricWidgets.add(_VibrantText(text: '$releaseYear · $durationOrSeasons', isDark: heroIsDark));
    } else if (hasYear) {
      metricWidgets.add(_VibrantText(text: releaseYear, isDark: heroIsDark));
    } else if (hasDuration) {
      metricWidgets.add(_VibrantText(text: durationOrSeasons, isDark: heroIsDark));
    }
    if (contentRating != null && contentRating.isNotEmpty && contentRating != 'N/A') {
      metricWidgets.add(_MaturityBadge(rated: contentRating, isDark: heroIsDark));
    }

    final hasDetails = (director != null && director.isNotEmpty && director != 'N/A') ||
        (writers != null && writers.isNotEmpty && writers != 'N/A') ||
        leadCast.isNotEmpty ||
        (awards != null && awards.isNotEmpty && awards != 'N/A') ||
        (releasedDate != null && releasedDate.isNotEmpty && releasedDate != 'N/A') ||
        (language != null && language.isNotEmpty && language != 'N/A') ||
        (country != null && country.isNotEmpty && country != 'N/A') ||
        (boxOffice != null && boxOffice.isNotEmpty && boxOffice != 'N/A');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: CupertinoPageScaffold(
        backgroundColor: scaffoldBgColor,
        child: Stack(
          children: [
          // Main Scrollable Body
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Apple TV Style Hero Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: isDark
                        ? BorderRadius.zero
                        : const BorderRadius.vertical(bottom: Radius.circular(32)),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  clipBehavior: isDark ? Clip.none : Clip.antiAlias,
                  child: Stack(
                    children: [
                      // A. High-Res Poster Artwork
                      if (heroImage != null && heroImage.isNotEmpty)
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: heroImage,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            fadeInDuration: const Duration(milliseconds: 150),
                          ),
                        ),

                      // B. Hardware-Accelerated Theatrical Dissolve (Zero offscreen GPU passes for 165Hz scrolling)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.28, 0.58, 0.85, 1.0],
                                colors: [
                                  Colors.black.withValues(alpha: 0.30),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.88),
                                  Colors.black,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // C. The Hero Editorial Content (Natural layout; sets the exact height of the Stack)
                      Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top breathing space for poster artwork
                          SizedBox(height: topArtSpacing),

                          // Optional Tagline Quote with Vibrancy
                          if (tagline != null && tagline.isNotEmpty) ...[
                            Text(
                              '"$tagline"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.75),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          // Content Title with Luminance & Subtle Translucency
                          Text(
                            entity.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _roundedFontFamily,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  blurRadius: 14,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle Line: "Movie · Crime · Drama" (Translucent, No Containers)
                          if (subtitleString.isNotEmpty) ...[
                            Text(
                              subtitleString,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                color: Colors.white.withValues(alpha: 0.82),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Synopsis with Apple TV inline MORE pill toggle (Left-aligned, justified flow)
                          if (overview.isNotEmpty) ...[
                            _AppleTvSynopsis(
                              text: overview,
                              isDark: heroIsDark,
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Metrics Row: Year · Runtime [Rating] 🍅 RT ★ IMDb (Bottom Left Aligned, Apple Weight)
                          if (metricWidgets.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: metricWidgets,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Post-Hero Editorial Body (Starts immediately after hero card)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                      // Where to Watch Card (Adaptive Light Grey Card)
                      WhereToWatchCard(
                        metadata: entity.metadata,
                        title: entity.title,
                        isDark: isDark,
                      ),

                      // Information Section (Apple style list with hairline dividers, no containers)
                      if (hasDetails) ...[
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'INFORMATION',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: pageSubtextColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (director != null && director.isNotEmpty && director != 'N/A')
                          _buildDetailRow(label: 'Director', value: director, textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark),
                        if (writers != null && writers.isNotEmpty && writers != 'N/A')
                          _buildDetailRow(label: 'Writers', value: writers, textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark),
                        if (leadCast.isNotEmpty)
                          _buildDetailRow(label: 'Cast', value: leadCast.join(', '), textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark),
                        if (releasedDate != null && releasedDate.isNotEmpty && releasedDate != 'N/A')
                          _buildDetailRow(label: 'Released', value: releasedDate, textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark),
                        if (language != null && language.isNotEmpty && language != 'N/A')
                          _buildDetailRow(label: 'Audio', value: language, textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark),
                        if (country != null && country.isNotEmpty && country != 'N/A')
                          _buildDetailRow(label: 'Country', value: country, textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark),
                        if (awards != null && awards.isNotEmpty && awards != 'N/A')
                          _buildDetailRow(label: 'Awards', value: awards, textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark, showDivider: (boxOffice != null && boxOffice.isNotEmpty && boxOffice != 'N/A')),
                        if (boxOffice != null && boxOffice.isNotEmpty && boxOffice != 'N/A')
                          _buildDetailRow(label: 'Box Office', value: boxOffice, textColor: pageTextColor, subtextColor: pageSubtextColor, isDark: isDark, showDivider: false),
                      ],

                      // Verified Outbound Link (IMDb Only, blended Apple TV style)
                      if (imdbId != null && imdbId.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'LINKS',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: pageSubtextColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AppleTvImdbLinkTile(imdbId: imdbId, isDark: isDark),
                      ],

                      SizedBox(height: 64 + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Floating Standardized Frosted Glass Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IntentDetailAppBar(
              title: formatLabel,
              titleLeading: Icon(
                isTv ? CupertinoIcons.tv : CupertinoIcons.film,
                size: 15,
                color: isDark ? CupertinoColors.white : const Color(0xFF1A1A1A),
              ),
              isDark: isDark,
              scaffoldBgColor: scaffoldBgColor,
              actions: [
                if (imdbId != null && imdbId.isNotEmpty)
                  IntentDetailAppBar.buildActionButton(
                    isDark: isDark,
                    onPressed: () {
                      final url = 'https://www.imdb.com/title/$imdbId/';
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Icon(
                      CupertinoIcons.link,
                      color: isDark ? CupertinoColors.white : const Color(0xFF1A1A1A),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  static Widget _buildDetailRow({
    required String label,
    required String value,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 95,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subtextColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: textColor.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: subtextColor.withValues(alpha: isDark ? 0.15 : 0.25),
          ),
      ],
    );
  }
}

/// Translucent vibrant metric text with Apple SF Pro weight
class _VibrantText extends StatelessWidget {
  final String text;
  final bool isDark;

  const _VibrantText({
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.88),
        shadows: isDark
            ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Apple TV Synopsis with inline [MORE] pill button at the end of line 2
class _AppleTvSynopsis extends StatefulWidget {
  final String text;
  final bool isDark;

  const _AppleTvSynopsis({
    required this.text,
    required this.isDark,
  });

  @override
  State<_AppleTvSynopsis> createState() => _AppleTvSynopsisState();
}

class _AppleTvSynopsisState extends State<_AppleTvSynopsis> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    final textColor = (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.88);
    final textStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      height: 1.38,
      letterSpacing: -0.12,
      color: textColor,
      shadows: widget.isDark
          ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: textStyle,
            maxLines: _isExpanded ? null : 2,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _isExpanded ? 'LESS' : 'MORE',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: widget.isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard film classification box [R] / [TV-MA]
class _MaturityBadge extends StatelessWidget {
  final String rated;
  final bool isDark;

  const _MaturityBadge({
    required this.rated,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.75),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        rated,
        style: TextStyle(
          fontFamily: _fontFamily,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.90),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Clean container-less Rotten Tomatoes score with tomato emoji and Apple weight
class _RottenTomatoesText extends StatelessWidget {
  final String score;
  final bool isDark;

  const _RottenTomatoesText({
    required this.score,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🍅', style: TextStyle(fontSize: 12.0)),
        const SizedBox(width: 2.5),
        Text(
          score,
          style: TextStyle(
            fontFamily: _fontFamily,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.92),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            shadows: isDark
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// Clean container-less IMDb rating with interactive tap sheet and Apple weight
class _RatingText extends StatelessWidget {
  final String rating;
  final String source;
  final String? votes;
  final String? rottenTomatoes;
  final String? metascore;
  final String? title;
  final bool isDark;

  const _RatingText({
    required this.rating,
    required this.source,
    this.votes,
    this.rottenTomatoes,
    this.metascore,
    this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRatingSheet(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('★', style: TextStyle(color: Color(0xFFFFD60A), fontSize: 13)),
          const SizedBox(width: 2.5),
          Text(
            '$rating $source',
            style: TextStyle(
              fontFamily: _fontFamily,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.95),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              shadows: isDark
                  ? [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingSheet(BuildContext context) {
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
            if (metascore != null && metascore!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Ⓜ Metacritic: $metascore',
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

/// Vibrant container-less Metascore text with Apple weight
class _MetascoreText extends StatelessWidget {
  final String score;
  final bool isDark;

  const _MetascoreText({
    required this.score,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ⓜ $score',
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.90),
        shadows: isDark
            ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Sleek Apple TV-style IMDb link tile that dynamically blends with light or dark theme
class _AppleTvImdbLinkTile extends StatefulWidget {
  final String imdbId;
  final bool isDark;

  const _AppleTvImdbLinkTile({
    required this.imdbId,
    required this.isDark,
  });

  @override
  State<_AppleTvImdbLinkTile> createState() => _AppleTvImdbLinkTileState();
}

class _AppleTvImdbLinkTileState extends State<_AppleTvImdbLinkTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () async {
        final uri = Uri.parse('https://www.imdb.com/title/${widget.imdbId}/');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Iconic Golden IMDb Logo Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C518),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'IMDb',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'View on IMDb',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1D1D1F),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.arrow_up_right,
                color: widget.isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF86868B),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
