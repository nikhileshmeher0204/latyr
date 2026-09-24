import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/shared/widgets/ambient_mesh_background.dart';
import 'package:latyr_app/shared/widgets/entities/github_repo_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/movie_show_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/place_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/quote_entity_card.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';
import 'package:latyr_app/shared/widgets/metric_stat_card.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final String title;
  final String subtitle;

  const CollectionDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureListAsync = ref.watch(captureListStreamProvider);
    final allCaptures = captureListAsync.valueOrNull ?? [];
    final matchingCaptures = allCaptures.where((c) {
      if (c.status != 'COMPLETED') return false;
      final cat = c.category?.toLowerCase() ?? '';
      final t = title.toLowerCase();
      if (t.contains('movie') || t.contains('show')) {
        return cat.contains('entertainment') ||
            cat.contains('movie') ||
            cat.contains('show');
      }
      return cat.contains(t) || t.contains(cat);
    }).toList();

    final entities = <ExtractedEntityModel>[];
    for (final c in matchingCaptures) {
      if (c.entitiesJson != null && c.entitiesJson!.isNotEmpty) {
        entities.addAll(ExtractedEntityModel.parseListFromJsonString(c.entitiesJson));
      }
    }

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return CupertinoPageScaffold(
      child: AmbientMeshBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            slivers: [
              // ── Inline Nav Bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LSpacing.screenH,
                    vertical: LSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassCard(
                        borderRadius: LSpacing.radiusPill,
                        padding: const EdgeInsets.all(LSpacing.sm + 2),
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          size: 17,
                          color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316),
                        ),
                      ),
                      Text(
                        title,
                        style: LTypography.footnoteSemibold.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GlassCard(
                        borderRadius: LSpacing.radiusPill,
                        padding: const EdgeInsets.all(LSpacing.sm + 2),
                        onTap: () {},
                        child: Icon(
                          CupertinoIcons.ellipsis,
                          size: 17,
                          color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LSpacing.screenH,
                  LSpacing.sm,
                  LSpacing.screenH,
                  LSpacing.navIslandClear,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      title,
                      style: LTypography.title1.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: LSpacing.xs - 1),
                    Text(
                      subtitle,
                      style: LTypography.footnote.copyWith(color: secondaryColor),
                    ),
                    const SizedBox(height: LSpacing.lg),

                    // Metric row
                    Row(
                      children: [
                        MetricStatCard(
                          value: '${matchingCaptures.length}',
                          label: 'captures',
                        ),
                        const SizedBox(width: LSpacing.sm),
                        MetricStatCard(
                          value: '${entities.length}',
                          label: 'items',
                        ),
                        const SizedBox(width: LSpacing.sm),
                        const MetricStatCard(
                          value: 'Active',
                          label: 'collection',
                          valueColor: LColors.brandAmberDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: LSpacing.xl),

                    Text(
                      'Saved Items',
                      style: LTypography.headline.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: LSpacing.md),

                    if (entities.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: LSpacing.xl),
                        child: Text(
                          'No items in this collection yet. Share content to Latyr to display here.',
                          style: LTypography.footnote.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      for (final entity in entities) ...[
                        _buildEntityCard(context, entity, labelColor, secondaryColor),
                        const SizedBox(height: LSpacing.md - 2),
                      ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntityCard(
    BuildContext context,
    ExtractedEntityModel entity,
    Color labelColor,
    Color secondaryColor,
  ) {
    final type = entity.entityType.toUpperCase();
    if (type == 'MOVIE' || type == 'TV_SHOW') {
      return MovieShowEntityCard(
        title: entity.title,
        description: entity.description,
        rating: double.tryParse(entity.metadata['rating']?.toString() ?? ''),
        releaseYearOrSeasons: entity.metadata['release_year']?.toString(),
        externalUrl: entity.externalUrl,
        posterUrl: entity.metadata['poster_url']?.toString(),
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
    } else {
      return GlassCard(
        borderRadius: LSpacing.radiusLG,
        padding: const EdgeInsets.all(LSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entity.title,
              style: LTypography.footnoteSemibold.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (entity.description != null && entity.description!.isNotEmpty) ...[
              const SizedBox(height: LSpacing.xs - 1),
              Text(
                entity.description!,
                style: LTypography.caption1.copyWith(color: secondaryColor),
              ),
            ],
          ],
        ),
      );
    }
  }
}
