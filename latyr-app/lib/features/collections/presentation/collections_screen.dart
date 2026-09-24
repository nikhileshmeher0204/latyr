import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/feed/presentation/widgets/capture_card_widget.dart';

class _CollectionItem {
  final String code;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(LocalCapture) matches;

  _CollectionItem({
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.matches,
  });
}

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capturesAsync = ref.watch(captureListStreamProvider);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    final collections = [
      _CollectionItem(
        code: 'WATCHLIST',
        name: 'Weekend Watchlist',
        description: 'Movies and TV series saved from Reels',
        icon: CupertinoIcons.film_fill,
        color: LColors.terracotta,
        matches: (c) =>
            c.intent?.toUpperCase() == 'WATCH' ||
            c.category?.toLowerCase() == 'entertainment' ||
            (c.entitiesJson?.contains('MOVIE') ?? false),
      ),
      _CollectionItem(
        code: 'PLACES',
        name: 'Places to Visit',
        description: 'Cafes, travel spots, and destinations',
        icon: CupertinoIcons.map_pin,
        color: LColors.info,
        matches: (c) =>
            c.intent?.toUpperCase() == 'VISIT' ||
            c.category?.toLowerCase() == 'places' ||
            (c.entitiesJson?.contains('PLACE') ?? false),
      ),
      _CollectionItem(
        code: 'DEV_TOOLS',
        name: 'Dev Tools & Repos',
        description: 'GitHub repositories, CLI tools, and libraries',
        icon: CupertinoIcons.command,
        color: LColors.sageEmerald,
        matches: (c) =>
            c.category?.toLowerCase() == 'technology' ||
            c.category?.toLowerCase() == 'tools' ||
            (c.entitiesJson?.contains('REPO') ?? false),
      ),
      _CollectionItem(
        code: 'RECIPES',
        name: 'Recipe Box',
        description: 'Dishes, ingredients, and cooking steps',
        icon: CupertinoIcons.flame_fill,
        color: LColors.warning,
        matches: (c) =>
            c.intent?.toUpperCase() == 'COOK' ||
            c.category?.toLowerCase() == 'food' ||
            (c.entitiesJson?.contains('RECIPE') ?? false),
      ),
      _CollectionItem(
        code: 'QUOTES',
        name: 'Wisdom & Quotes',
        description: 'Notable insights and quotes from creators',
        icon: CupertinoIcons.text_quote,
        color: LColors.royalViolet,
        matches: (c) =>
            c.category?.toLowerCase() == 'quotes' ||
            (c.entitiesJson?.contains('QUOTE') ?? false),
      ),
    ];

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Collections'),
            border: null,
          ),
          capturesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $err', style: LTypography.footnote.copyWith(color: LColors.error)),
              ),
            ),
            data: (allCaptures) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: LSpacing.sm, bottom: LSpacing.xl3),
                  child: CupertinoListSection.insetGrouped(
                    header: Text(
                      'SMART COLLECTIONS',
                      style: LTypography.caption1.copyWith(color: secondaryColor),
                    ),
                    children: collections.map((col) {
                      final count = allCaptures.where(col.matches).length;
                      return CupertinoListTile.notched(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: col.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              col.icon,
                              color: CupertinoColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          col.name,
                          style: LTypography.body.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          col.description,
                          style: LTypography.caption1.copyWith(color: secondaryColor),
                        ),
                        additionalInfo: Text(
                          '$count',
                          style: LTypography.subhead.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          final matching = allCaptures.where(col.matches).toList();
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => _CollectionDetailPage(
                                collection: col,
                                captures: matching,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CollectionDetailPage extends StatelessWidget {
  final _CollectionItem collection;
  final List<LocalCapture> captures;

  const _CollectionDetailPage({
    required this.collection,
    required this.captures,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(collection.name, style: LTypography.headline.copyWith(color: labelColor)),
        previousPageTitle: 'Collections',
      ),
      child: SafeArea(
        child: captures.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(LSpacing.xl2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(LSpacing.lg),
                        decoration: BoxDecoration(
                          color: collection.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(collection.icon, size: 40, color: collection.color),
                      ),
                      const SizedBox(height: LSpacing.base),
                      Text(
                        'Empty Collection',
                        style: LTypography.title2.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: LSpacing.xs),
                      Text(
                        'Items matching "${collection.name}" will automatically be organized here.',
                        textAlign: TextAlign.center,
                        style: LTypography.footnote.copyWith(color: secondaryColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(
                  decelerationRate: ScrollDecelerationRate.fast,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: LSpacing.screenH,
                  vertical: LSpacing.md,
                ),
                itemCount: captures.length,
                separatorBuilder: (context, i) => const SizedBox(height: LSpacing.md),
                itemBuilder: (context, index) => CaptureCardWidget(
                  key: ValueKey(captures[index].id),
                  capture: captures[index],
                ),
              ),
      ),
    );
  }
}
