import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/shared/widgets/ambient_mesh_background.dart';
import 'package:latyr_app/shared/widgets/entities/github_repo_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/movie_show_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/place_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/quote_entity_card.dart';
import 'package:latyr_app/shared/widgets/filter_chip_bar.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedFilterIndex = 0;

  final List<FilterChipItem> _filters = const [
    FilterChipItem(label: 'All'),
    FilterChipItem(label: 'Shows', iconText: '▶'),
    FilterChipItem(label: 'Quotes', iconText: '"'),
    FilterChipItem(label: 'Repos', iconText: '⌘'),
    FilterChipItem(label: 'Places', iconText: '📍'),
  ];

  @override
  Widget build(BuildContext context) {
    final captureListAsync = ref.watch(captureListStreamProvider);
    final allCaptures = captureListAsync.valueOrNull ?? [];
    final completedCaptures = allCaptures.where((c) => c.status == 'COMPLETED').toList();

    // Parse all extracted entities
    final allEntities = <ExtractedEntityModel>[];
    for (final c in completedCaptures) {
      if (c.entitiesJson != null && c.entitiesJson!.isNotEmpty) {
        allEntities.addAll(ExtractedEntityModel.parseListFromJsonString(c.entitiesJson));
      }
    }

    // Filter items based on selected tab
    final selectedFilterLabel = _filters[_selectedFilterIndex].label;
    final List<Widget> entityWidgets = [];

    for (final entity in allEntities) {
      final type = entity.entityType.toUpperCase();
      if (selectedFilterLabel == 'Shows' && type != 'MOVIE' && type != 'TV_SHOW') continue;
      if (selectedFilterLabel == 'Quotes' && type != 'QUOTE') continue;
      if (selectedFilterLabel == 'Repos' && type != 'GITHUB_REPO' && type != 'REPO') continue;
      if (selectedFilterLabel == 'Places' && type != 'PLACE' && type != 'LOCATION') continue;

      entityWidgets.add(_buildEntityWidget(entity, type));
    }

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return AmbientMeshBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LSpacing.screenH,
                LSpacing.screenTop,
                LSpacing.screenH,
                LSpacing.navIslandClear,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Large Title ──────────────────────────────────────────────
                  Text(
                    'Library',
                    style: LTypography.largeTitle.copyWith(color: labelColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All captures, shaped by what they are.',
                    style: LTypography.footnote.copyWith(color: secondaryColor),
                  ),
                  const SizedBox(height: LSpacing.lg - 2),

                  // ── Filter Chips ─────────────────────────────────────────────
                  FilterChipBar(
                    items: _filters,
                    selectedIndex: _selectedFilterIndex,
                    onSelected: (idx) => setState(() => _selectedFilterIndex = idx),
                  ),
                  const SizedBox(height: LSpacing.lg),

                  // ── Content ──────────────────────────────────────────────────
                  if (entityWidgets.isEmpty)
                    _buildEmptyState(secondaryColor, labelColor)
                  else
                    // 2-column masonry grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (int i = 0; i < entityWidgets.length; i += 2) ...[
                                entityWidgets[i],
                                const SizedBox(height: LSpacing.md),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: LSpacing.md),
                        Expanded(
                          child: Column(
                            children: [
                              for (int i = 1; i < entityWidgets.length; i += 2) ...[
                                entityWidgets[i],
                                const SizedBox(height: LSpacing.md),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityWidget(ExtractedEntityModel entity, String type) {
    if (type == 'MOVIE' || type == 'TV_SHOW') {
      final meta = entity.metadata;
      final isTv = (meta['media_type']?.toString().toLowerCase() == 'tv' || type == 'TV_SHOW');
      final mediaTypeLabel = isTv ? 'Series' : 'Movie';
      final year = meta['release_year']?.toString();
      final durationOrSeasons = isTv
          ? meta['seasons_formatted']?.toString()
          : meta['runtime_formatted']?.toString();
      final subtitleParts = [
        mediaTypeLabel,
        if (year != null && year.isNotEmpty) year,
        if (durationOrSeasons != null && durationOrSeasons.isNotEmpty) durationOrSeasons,
      ].join(' · ');

      return MovieShowEntityCard(
        title: entity.title,
        description: entity.description ?? meta['tagline']?.toString(),
        rating: double.tryParse(meta['rating']?.toString() ?? ''),
        releaseYearOrSeasons: subtitleParts.isNotEmpty ? subtitleParts : null,
        externalUrl: entity.externalUrl,
        posterUrl: meta['poster_url']?.toString(),
      );
    } else if (type == 'GITHUB_REPO' || type == 'REPO') {
      return GitHubRepoEntityCard(
        title: entity.title,
        description: entity.description,
        language: entity.metadata['language']?.toString(),
        stars: int.tryParse(entity.metadata['stars']?.toString() ?? ''),
        externalUrl: entity.externalUrl,
      );
    } else if (type == 'QUOTE') {
      return QuoteEntityCard(
        quoteText: entity.title,
        authorOrAttribution: entity.description ?? 'Saved Quote',
      );
    } else if (type == 'PLACE' || type == 'LOCATION') {
      return PlaceEntityCard(
        name: entity.title,
        location: entity.metadata['location']?.toString() ?? entity.title,
        notesSummary: entity.description,
      );
    }

    // Generic fallback
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);
    return GlassCard(
      borderRadius: LSpacing.radiusLG,
      padding: const EdgeInsets.all(LSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entity.title,
            style: LTypography.footnoteSemibold.rounded.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: LSpacing.xs),
            Text(
              entity.description!,
              style: LTypography.caption1.copyWith(color: secondaryColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LSpacing.xl2, horizontal: LSpacing.sm),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 40,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(height: LSpacing.md),
            Text(
              'No items in this section.',
              textAlign: TextAlign.center,
              style: LTypography.subheadlineMedium.rounded.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LSpacing.xs),
            Text(
              'Share content to Latyr to display here.',
              textAlign: TextAlign.center,
              style: LTypography.footnote.copyWith(color: secondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
