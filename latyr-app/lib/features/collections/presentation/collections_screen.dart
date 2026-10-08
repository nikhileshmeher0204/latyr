import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/collections/presentation/category_detail_screen.dart';
import 'package:latyr_app/features/collections/presentation/collections_providers.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootCollectionsAsync = ref.watch(rootCollectionsProvider);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

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
          rootCollectionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $err', style: LTypography.footnote.copyWith(color: LColors.error)),
              ),
            ),
            data: (collections) {
              if (collections.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No collections yet.',
                      style: LTypography.body.copyWith(color: secondaryColor),
                    ),
                  ),
                );
              }
              
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: LSpacing.sm, bottom: LSpacing.xl3),
                  child: CupertinoListSection.insetGrouped(
                    header: Text(
                      'SMART COLLECTIONS',
                      style: LTypography.roundedEyebrow.copyWith(color: secondaryColor),
                    ),
                    children: collections.map((col) {
                      final count = col.captures.length;
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
                          col.categoryName,
                          style: LTypography.body.rounded.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        additionalInfo: Text(
                          '$count',
                          style: LTypography.subhead.rounded.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => CategoryDetailScreen(
                                categoryGroup: col,
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
