import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_app_bar.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_scaffold.dart';
import 'package:latyr_app/features/collections/presentation/screens/collection_detail_screen.dart';
import 'package:latyr_app/features/collections/presentation/user_collections_provider.dart';
import 'package:latyr_app/features/collections/presentation/widgets/latyr_stacked_artwork_card.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  void _showCreateCollectionDialog(BuildContext context) {
    final textController = TextEditingController();
    final descController = TextEditingController();

    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Collection'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: textController,
              placeholder: 'Collection Name (e.g. Crime Thrillers)',
              autofocus: true,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: descController,
              placeholder: 'Description (optional)',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop();
                final desc = descController.text.trim().isEmpty ? null : descController.text.trim();
                await ref.read(userCollectionsProvider.notifier).createCollection(
                  name: name,
                  description: desc,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final topPadding = MediaQuery.paddingOf(context).top;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.6)
        : const Color(0xFF8E8E93);
    final collectionsAsync = ref.watch(userCollectionsProvider);

    return LatyrScaffold(
      backgroundColor: scaffoldBg,
      appBar: LatyrAppBar(
        title: 'COLLECTIONS',
        titleLeading: const Icon(CupertinoIcons.folder_fill, size: 16),
        isDark: isDark,
        scaffoldBgColor: scaffoldBg,
        isPersistent: false,
        showBackButton: false,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              HapticFeedback.lightImpact();
              _showCreateCollectionDialog(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0x33FFFFFF) : const Color(0x0C000000),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.add,
                size: 20,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topPadding + 64.0),
          ),

          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(userCollectionsProvider);
              await ref.read(userCollectionsProvider.future);
            },
          ),

          collectionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(radius: 14),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(LSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Failed to load collections',
                        style: LTypography.body.copyWith(color: LColors.error),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        onPressed: () => ref.refresh(userCollectionsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (collections) {
              if (collections.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(LSpacing.xl2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(LSpacing.xl),
                            decoration: BoxDecoration(
                              color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.folder_badge_plus,
                              size: 44,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: LSpacing.base),
                          Text(
                            'Personal Curated Lists',
                            style: LTypography.roundedTitle2.copyWith(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Group movies, TV shows, and GitHub repos from your captures into custom collections.',
                            textAlign: TextAlign.center,
                            style: LTypography.caption1.copyWith(
                              color: secondaryTextColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: LSpacing.xl),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showCreateCollectionDialog(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.add,
                                    size: 16,
                                    color: isDark ? CupertinoColors.black : CupertinoColors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Create Collection',
                                    style: LTypography.footnoteSemibold.rounded.copyWith(
                                      color: isDark ? CupertinoColors.black : CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
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

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH, vertical: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final collection = collections[index];
                      return LatyrStackedArtworkCard(
                        collection: collection,
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => CollectionDetailScreen(collection: collection),
                            ),
                          );
                        },
                      );
                    },
                    childCount: collections.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}
