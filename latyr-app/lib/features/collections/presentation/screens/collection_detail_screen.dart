import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_app_bar.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_scaffold.dart';
import 'package:latyr_app/features/collections/domain/user_collection_model.dart';
import 'package:latyr_app/features/collections/presentation/user_collections_provider.dart';
import 'package:latyr_app/features/feed/presentation/widgets/entity_cards.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final UserCollectionModel collection;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends ConsumerState<CollectionDetailScreen> {
  late UserCollectionModel _currentCollection;

  @override
  void initState() {
    super.initState();
    _currentCollection = widget.collection;
  }

  void _showOptionsMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(_currentCollection.name),
        message: const Text('Manage Collection'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showEditDialog(context);
            },
            child: const Text('Edit Details'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _confirmDelete(context);
            },
            child: const Text('Delete Collection'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final textController = TextEditingController(text: _currentCollection.name);
    final descController = TextEditingController(text: _currentCollection.description ?? '');

    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Edit Collection'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: textController,
              placeholder: 'Collection Name',
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
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();
                final newDesc = descController.text.trim().isEmpty ? null : descController.text.trim();
                await ref.read(userCollectionsProvider.notifier).updateCollection(
                  _currentCollection.id,
                  name: newName,
                  description: newDesc,
                );
                setState(() {
                  _currentCollection = _currentCollection.copyWith(
                    name: newName,
                    description: newDesc,
                  );
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Are you sure you want to delete "${_currentCollection.name}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(userCollectionsProvider.notifier).deleteCollection(_currentCollection.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete'),
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
    final entitiesAsync = ref.watch(collectionEntitiesProvider(_currentCollection.id));

    return LatyrScaffold(
      backgroundColor: scaffoldBg,
      appBar: LatyrAppBar(
        title: _currentCollection.name.toUpperCase(),
        titleLeading: const Icon(CupertinoIcons.folder_fill, size: 16),
        isDark: isDark,
        scaffoldBgColor: scaffoldBg,
        isPersistent: false,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              HapticFeedback.lightImpact();
              _showOptionsMenu(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0x33FFFFFF) : const Color(0x0C000000),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.ellipsis,
                size: 18,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header summary
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 64.0,
                left: LSpacing.screenH,
                right: LSpacing.screenH,
                bottom: LSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentCollection.description != null &&
                      _currentCollection.description!.isNotEmpty) ...[
                    Text(
                      _currentCollection.description!,
                      style: LTypography.body.copyWith(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  entitiesAsync.when(
                    data: (entities) => Text(
                      '${entities.length} ${entities.length == 1 ? "item" : "items"} saved',
                      style: LTypography.caption1.rounded.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, error) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Entities List
          entitiesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(radius: 14),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error loading collection items: $err',
                  style: LTypography.footnote.copyWith(color: LColors.error),
                ),
              ),
            ),
            data: (entities) {
              if (entities.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(LSpacing.xl2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(LSpacing.lg),
                            decoration: BoxDecoration(
                              color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.tray,
                              size: 38,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: LSpacing.base),
                          Text(
                            'No items in this collection',
                            style: LTypography.roundedTitle2.copyWith(
                              color: textColor,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add movies, shows, repositories or places from your captures using the "+" button.',
                            textAlign: TextAlign.center,
                            style: LTypography.caption1.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entity = entities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(entity.id ?? '$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: CupertinoColors.destructiveRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              CupertinoIcons.trash,
                              color: CupertinoColors.white,
                              size: 24,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (entity.id == null) return false;
                            await ref.read(userCollectionsProvider.notifier).removeEntityFromCollection(
                              _currentCollection.id,
                              entity.id!,
                            );
                            return true;
                          },
                          child: EntityCardRouter(
                            entity: entity,
                            categoryTitle: _currentCollection.name,
                          ),
                        ),
                      );
                    },
                    childCount: entities.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
