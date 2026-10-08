import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/shared/widgets/entities/github_repo_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/movie_show_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/place_entity_card.dart';
import 'package:latyr_app/shared/widgets/entities/quote_entity_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _selectedScope = 0; // 0 = All, 1 = Movies, 2 = Places, 3 = Repos, 4 = Quotes

  final List<String> _scopes = const ['All', 'Movies', 'Places', 'Repos', 'Quotes'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureListAsync = ref.watch(captureListStreamProvider);
    final allCaptures = captureListAsync.valueOrNull ?? [];
    final completedCaptures = allCaptures.where((c) => c.status == 'COMPLETED').toList();

    final allEntities = <ExtractedEntityModel>[];
    for (final c in completedCaptures) {
      if (c.entitiesJson != null && c.entitiesJson!.isNotEmpty) {
        allEntities.addAll(ExtractedEntityModel.parseListFromJsonString(c.entitiesJson));
      }
    }

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final inputBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    // Apply Scope & Query Filter
    final filteredEntities = allEntities.where((e) {
      final type = e.entityType.toUpperCase();
      if (_selectedScope == 1 && type != 'MOVIE' && type != 'TV_SHOW') return false;
      if (_selectedScope == 2 && type != 'PLACE' && type != 'LOCATION') return false;
      if (_selectedScope == 3 && type != 'GITHUB_REPO' && type != 'REPO') return false;
      if (_selectedScope == 4 && type != 'QUOTE') return false;

      if (_query.isEmpty) return true;
      final titleMatch = e.title.toLowerCase().contains(_query);
      final descMatch = e.description?.toLowerCase().contains(_query) ?? false;
      final typeMatch = e.entityType.toLowerCase().contains(_query);
      return titleMatch || descMatch || typeMatch;
    }).toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Search'),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH, vertical: LSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Apple Search Field ────────────────────────────────────
                  CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search saved movies, places, notes…',
                    placeholderStyle: LTypography.body.copyWith(
                      color: CupertinoColors.placeholderText.resolveFrom(context),
                    ),
                    style: LTypography.body.copyWith(color: labelColor),
                    backgroundColor: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(horizontal: LSpacing.sm, vertical: 10),
                  ),
                  const SizedBox(height: LSpacing.sm),

                  // ── Scope / Filter Pills ──────────────────────────────────
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _scopes.length,
                      separatorBuilder: (context, i) => const SizedBox(width: LSpacing.xs),
                      itemBuilder: (context, index) {
                        final scope = _scopes[index];
                        final isSelected = _selectedScope == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedScope = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: LSpacing.md, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LColors.brandAmber
                                  : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                scope,
                                style: LTypography.caption1.rounded.copyWith(
                                  color: isSelected ? CupertinoColors.white : secondaryColor,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: LSpacing.md),
                ],
              ),
            ),
          ),

          // ── Search Results ────────────────────────────────────────────────
          if (filteredEntities.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(LSpacing.xl2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 40,
                        color: CupertinoColors.systemGrey3.resolveFrom(context),
                      ),
                      const SizedBox(height: LSpacing.md),
                      Text(
                        _query.isEmpty ? 'No items in this scope' : 'No results found for "$_query"',
                        style: LTypography.headline.rounded.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: LSpacing.xs),
                      Text(
                        'Try searching for a title, creator name, or change the filter above.',
                        textAlign: TextAlign.center,
                        style: LTypography.footnote.copyWith(color: secondaryColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LSpacing.screenH,
                0,
                LSpacing.screenH,
                LSpacing.xl3,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: LSpacing.md),
                    child: _buildEntityCard(filteredEntities[index]),
                  ),
                  childCount: filteredEntities.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntityCard(ExtractedEntityModel entity) {
    final type = entity.entityType.toUpperCase();
    if (type == 'GITHUB_REPO' || type == 'REPO') {
      return GitHubRepoEntityCard(
        title: entity.title,
        description: entity.description,
        language: entity.metadata['language']?.toString(),
        stars: int.tryParse(entity.metadata['stars']?.toString() ?? ''),
        externalUrl: entity.externalUrl,
      );
    } else if (type == 'MOVIE' || type == 'TV_SHOW') {
      return MovieShowEntityCard(
        title: entity.title,
        description: entity.description,
        rating: double.tryParse(entity.metadata['rating']?.toString() ?? ''),
        releaseYearOrSeasons: entity.metadata['release_year']?.toString(),
        externalUrl: entity.externalUrl,
        posterUrl: entity.metadata['poster_url']?.toString(),
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

    // Generic fallback Apple card
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(LSpacing.base),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entity.title,
            style: LTypography.body.rounded.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: LSpacing.xs),
            Text(
              entity.description!,
              style: LTypography.footnote.copyWith(color: secondaryColor),
            ),
          ],
        ],
      ),
    );
  }
}
