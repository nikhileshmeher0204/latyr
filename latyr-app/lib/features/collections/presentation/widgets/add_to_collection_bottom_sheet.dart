import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/collections/presentation/user_collections_provider.dart';

class AddToCollectionBottomSheet extends ConsumerStatefulWidget {
  final ExtractedEntityModel entity;
  final String? suggestedCollectionName;

  const AddToCollectionBottomSheet({
    super.key,
    required this.entity,
    this.suggestedCollectionName,
  });

  static void show(
    BuildContext context, {
    required ExtractedEntityModel entity,
    String? suggestedCollectionName,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => AddToCollectionBottomSheet(
        entity: entity,
        suggestedCollectionName: suggestedCollectionName,
      ),
    );
  }

  @override
  ConsumerState<AddToCollectionBottomSheet> createState() =>
      _AddToCollectionBottomSheetState();
}

class _AddToCollectionBottomSheetState
    extends ConsumerState<AddToCollectionBottomSheet> {
  bool _isCreatingInline = false;
  final TextEditingController _newCollectionController = TextEditingController();

  @override
  void dispose() {
    _newCollectionController.dispose();
    super.dispose();
  }

  IconData _parseIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'film':
      case 'movie':
        return CupertinoIcons.film;
      case 'tv':
      case 'series':
        return CupertinoIcons.tv;
      case 'code':
      case 'dev':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'book':
      case 'learn':
        return CupertinoIcons.book;
      case 'heart':
      case 'favorite':
        return CupertinoIcons.heart_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'folder':
      default:
        return CupertinoIcons.folder_fill;
    }
  }

  Color _parseColor(String? hex, bool isDark) {
    if (hex != null && hex.isNotEmpty) {
      try {
        final clean = hex.replaceAll('#', '');
        final intVal = int.parse(clean, radix: 16);
        return Color(clean.length == 6 ? 0xFF000000 | intVal : intVal);
      } catch (_) {}
    }
    return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
  }

  Future<void> _createAndAdd(String name) async {
    if (widget.entity.id == null || name.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final created = await ref
        .read(userCollectionsProvider.notifier)
        .createCollection(name: name.trim());
    await ref
        .read(userCollectionsProvider.notifier)
        .addEntityToCollection(created.id, widget.entity.id!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.6)
        : const Color(0xFF8E8E93);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    final collectionsAsync = ref.watch(userCollectionsProvider);
    final entityId = widget.entity.id;
    final entityCollectionIdsAsync = entityId != null
        ? ref.watch(entityCollectionIdsProvider(entityId))
        : const AsyncValue.data(<String>{});

    final memberCollectionIds = entityCollectionIdsAsync.valueOrNull ?? <String>{};

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Notch Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header Row: Title & Done
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save to Collection',
                          style: LTypography.roundedTitle2.copyWith(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.entity.title,
                          style: LTypography.caption1.copyWith(
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Done',
                      style: LTypography.body.rounded.copyWith(
                        color: CupertinoColors.activeBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 0.8, color: borderColor),

            // Scrollable Content
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Smart Suggestion Banner (if suggested collection doesn't exist yet)
                  if (widget.suggestedCollectionName != null &&
                      widget.suggestedCollectionName!.isNotEmpty)
                    collectionsAsync.when(
                      data: (collections) {
                        final exists = collections.any((c) =>
                            c.name.toLowerCase() ==
                            widget.suggestedCollectionName!.toLowerCase());
                        if (exists) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () async {
                              await _createAndAdd(widget.suggestedCollectionName!);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeBlue
                                    .withValues(alpha: isDark ? 0.18 : 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: CupertinoColors.activeBlue
                                      .withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeBlue
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.sparkles,
                                      color: CupertinoColors.activeBlue,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create "${widget.suggestedCollectionName}"',
                                          style: LTypography.footnoteSemibold.rounded
                                              .copyWith(
                                            color: isDark
                                                ? CupertinoColors.white
                                                : CupertinoColors.activeBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Suggested from capture subcategory',
                                          style: LTypography.caption2.copyWith(
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.add,
                                    color: CupertinoColors.activeBlue,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                  // Collections List
                  collectionsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Error loading collections: $err',
                          style: LTypography.footnote.copyWith(
                            color: LColors.error,
                          ),
                        ),
                      ),
                    ),
                    data: (collections) {
                      if (collections.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No collections yet. Create your first one below.',
                              style: LTypography.caption1.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: collections.map((col) {
                          final isMember = memberCollectionIds.contains(col.id);
                          final colColor = _parseColor(col.colorHex, isDark);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () async {
                                if (entityId == null) return;
                                HapticFeedback.selectionClick();
                                final notifier = ref.read(userCollectionsProvider.notifier);
                                if (isMember) {
                                  await notifier.removeEntityFromCollection(col.id, entityId);
                                } else {
                                  await notifier.addEntityToCollection(col.id, entityId);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E).withValues(alpha: 0.5)
                                      : const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: colColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _parseIcon(col.icon),
                                        color: colColor,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            col.name,
                                            style: LTypography.body.rounded.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            '${col.itemCount} items',
                                            style: LTypography.caption2.copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isMember
                                            ? CupertinoColors.activeGreen
                                            : CupertinoColors.transparent,
                                        border: Border.all(
                                          color: isMember
                                              ? CupertinoColors.activeGreen
                                              : (isDark
                                                  ? const Color(0xFF48484A)
                                                  : const Color(0xFFC7C7CC)),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isMember
                                          ? const Icon(
                                              CupertinoIcons.check_mark,
                                              size: 14,
                                              color: CupertinoColors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Inline New Collection Creation
                  if (_isCreatingInline) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: _newCollectionController,
                            placeholder: 'Collection name',
                            autofocus: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onSubmitted: (val) async {
                              if (val.trim().isNotEmpty) {
                                await _createAndAdd(val);
                                setState(() {
                                  _isCreatingInline = false;
                                  _newCollectionController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          onPressed: () async {
                            final val = _newCollectionController.text.trim();
                            if (val.isNotEmpty) {
                              await _createAndAdd(val);
                              setState(() {
                                _isCreatingInline = false;
                                _newCollectionController.clear();
                              });
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ] else ...[
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () {
                        setState(() => _isCreatingInline = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.add,
                              size: 16,
                              color: CupertinoColors.activeBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'New Collection',
                              style: LTypography.body.rounded.copyWith(
                                color: CupertinoColors.activeBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
