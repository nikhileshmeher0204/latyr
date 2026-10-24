import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/widgets/latyr_capture_card.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_app_bar.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_scaffold.dart';
import 'package:latyr_app/features/collections/domain/collection_models.dart';

class SubCategoryDetailScreen extends ConsumerWidget {
  final SubCategoryGroup subCategoryGroup;
  final Color parentCategoryColor;

  const SubCategoryDetailScreen({
    super.key,
    required this.subCategoryGroup,
    required this.parentCategoryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final labelColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final captures = subCategoryGroup.captures;
    final topPadding = MediaQuery.paddingOf(context).top;

    return LatyrScaffold(
      backgroundColor: scaffoldBg,
      appBar: LatyrAppBar(
        title: subCategoryGroup.subCategoryName,
        titleLeading: Icon(CupertinoIcons.folder_fill, size: 16, color: parentCategoryColor),
        isDark: isDark,
        scaffoldBgColor: scaffoldBg,
      ),
      body: captures.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(LSpacing.xl2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(LSpacing.lg),
                      decoration: BoxDecoration(
                        color: parentCategoryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.folder_open, size: 40, color: parentCategoryColor),
                    ),
                    const SizedBox(height: LSpacing.base),
                    Text(
                      'Empty Sub-Collection',
                      style: LTypography.roundedTitle2.copyWith(
                        color: labelColor,
                      ),
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
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: LSpacing.screenH,
                    right: LSpacing.screenH,
                    top: topPadding + 68,
                    bottom: LSpacing.md,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.70,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => LatyrCaptureCard(
                        key: ValueKey(captures[index].id),
                        capture: captures[index],
                      ),
                      childCount: captures.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: LSpacing.xl3),
                ),
              ],
            ),
    );
  }
}
