import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/collections/domain/collection_models.dart';
import 'package:latyr_app/features/collections/presentation/collections_providers.dart';
import 'package:latyr_app/features/collections/presentation/subcategory_detail_screen.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final CategoryGroup categoryGroup;

  const CategoryDetailScreen({
    super.key,
    required this.categoryGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final collection = categoryGroup;
    
    // Watch the subCategories for this category
    final subCategories = ref.watch(subCategoriesProvider(collection.categoryName));

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(collection.categoryName, style: LTypography.headline.rounded.copyWith(color: labelColor)),
        previousPageTitle: 'Collections',
      ),
      child: SafeArea(
        child: subCategories.isEmpty
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
                        style: LTypography.roundedTitle2.copyWith(
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: LSpacing.xs),
                      Text(
                        'Items matching "${collection.categoryName}" will automatically be organized here.',
                        textAlign: TextAlign.center,
                        style: LTypography.footnote.copyWith(color: secondaryColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(
                  decelerationRate: ScrollDecelerationRate.fast,
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: LSpacing.sm, bottom: LSpacing.xl3),
                      child: CupertinoListSection.insetGrouped(
                        header: Text(
                          'SUB-COLLECTIONS',
                          style: LTypography.roundedEyebrow.copyWith(color: secondaryColor),
                        ),
                        children: subCategories.map((subGroup) {
                          return CupertinoListTile.notched(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: collection.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.folder_fill,
                                  color: collection.color,
                                  size: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              subGroup.subCategoryName,
                              style: LTypography.body.rounded.copyWith(
                                color: labelColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            additionalInfo: Text(
                              '${subGroup.captures.length}',
                              style: LTypography.subhead.rounded.copyWith(
                                color: secondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const CupertinoListTileChevron(),
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) => SubCategoryDetailScreen(
                                    subCategoryGroup: subGroup,
                                    parentCategoryColor: collection.color,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
