import 'package:cached_network_image/cached_network_image.dart';
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

  String? _getEntityArtworkUrl(ExtractedEntityModel entity) {
    if (entity.entertainment.posterUrl != null && entity.entertainment.posterUrl!.isNotEmpty) {
      return entity.entertainment.posterUrl;
    }
    if (entity.entertainment.backdropUrl != null && entity.entertainment.backdropUrl!.isNotEmpty) {
      return entity.entertainment.backdropUrl;
    }
    if (entity.gitHubRepo.avatarUrl != null && entity.gitHubRepo.avatarUrl!.isNotEmpty) {
      return entity.gitHubRepo.avatarUrl;
    }
    return null;
  }

  Color _getEntityTypeColor(String type, bool isDark) {
    switch (type.toUpperCase()) {
      case 'MOVIE':
      case 'MOVIES':
        return const Color(0xFFE07A5F); // Terracotta
      case 'TV_SHOW':
      case 'TV SERIES':
      case 'SERIES':
        return const Color(0xFFD4A373); // Warm Sand
      case 'GITHUB_REPO':
      case 'CODE':
      case 'DEV':
        return const Color(0xFF81B29A); // Sage Green
      case 'BOOK':
        return const Color(0xFFF2CC8F); // Soft Gold
      default:
        return const Color(0xFF78E4A5); // Latyr Mint
    }
  }

  IconData _getEntityTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MOVIE':
      case 'MOVIES':
        return CupertinoIcons.film;
      case 'TV_SHOW':
      case 'TV SERIES':
      case 'SERIES':
        return CupertinoIcons.tv;
      case 'GITHUB_REPO':
      case 'CODE':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'BOOK':
        return CupertinoIcons.book;
      default:
        return CupertinoIcons.lightbulb_fill;
    }
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
    final sheetBg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF262629) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.6)
        : const Color(0xFF8E8E93);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEBEBEB);

    const latyrGreen = Color(0xFF28543A);
    const mintAccent = Color(0xFF78E4A5);
    final brandPrimary = isDark ? mintAccent : latyrGreen;

    final collectionsAsync = ref.watch(userCollectionsProvider);
    final entityId = widget.entity.id;
    final entityCollectionIdsAsync = entityId != null
        ? ref.watch(entityCollectionIdsProvider(entityId))
        : const AsyncValue.data(<String>{});

    final memberCollectionIds = entityCollectionIdsAsync.valueOrNull ?? <String>{};

    final artworkUrl = _getEntityArtworkUrl(widget.entity);
    final entityColor = _getEntityTypeColor(widget.entity.entityType, isDark);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row: Title & Circular Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Save to Collection',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Entity Mini Preview Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Artwork Thumbnail or Entity Icon Badge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 42,
                        height: 42,
                        color: entityColor.withValues(alpha: 0.15),
                        child: artworkUrl != null
                            ? CachedNetworkImage(
                                imageUrl: artworkUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: Icon(
                                    _getEntityTypeIcon(widget.entity.entityType),
                                    size: 18,
                                    color: entityColor,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    _getEntityTypeIcon(widget.entity.entityType),
                                    size: 18,
                                    color: entityColor,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  _getEntityTypeIcon(widget.entity.entityType),
                                  size: 20,
                                  color: entityColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.entity.title,
                            style: LTypography.body.rounded.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: entityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.entity.entityType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: entityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  // Smart Suggestion Banner
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? mintAccent.withValues(alpha: 0.14)
                                    : latyrGreen.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? mintAccent.withValues(alpha: 0.3)
                                      : latyrGreen.withValues(alpha: 0.2),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? mintAccent.withValues(alpha: 0.2)
                                          : latyrGreen.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.sparkles,
                                      color: brandPrimary,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create "${widget.suggestedCollectionName}"',
                                          style: LTypography.footnoteSemibold.rounded.copyWith(
                                            color: isDark ? mintAccent : latyrGreen,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'Suggested from capture category',
                                          style: LTypography.caption2.copyWith(
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? mintAccent.withValues(alpha: 0.2)
                                          : latyrGreen.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.add,
                                      color: brandPrimary,
                                      size: 16,
                                    ),
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
                            padding: const EdgeInsets.only(bottom: 8),
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isMember
                                        ? brandPrimary.withValues(alpha: 0.4)
                                        : borderColor,
                                    width: isMember ? 1.2 : 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CupertinoColors.black.withValues(
                                        alpha: isDark ? 0.2 : (isMember ? 0.05 : 0.025),
                                      ),
                                      blurRadius: isMember ? 8 : 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Collection artwork thumbnail or colorful icon tile
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        color: colColor.withValues(alpha: 0.15),
                                        child: col.previewArtworkUrls.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: col.previewArtworkUrls.first,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Center(
                                                  child: Icon(
                                                    _parseIcon(col.icon),
                                                    color: colColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Center(
                                                  child: Icon(
                                                    _parseIcon(col.icon),
                                                    color: colColor,
                                                    size: 18,
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Icon(
                                                  _parseIcon(col.icon),
                                                  color: colColor,
                                                  size: 18,
                                                ),
                                              ),
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
                                          const SizedBox(height: 1),
                                          Text(
                                            '${col.itemCount} ${col.itemCount == 1 ? 'item' : 'items'}',
                                            style: LTypography.caption2.copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Circular animated selection checkmark
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isMember ? brandPrimary : CupertinoColors.transparent,
                                        border: Border.all(
                                          color: isMember
                                              ? brandPrimary
                                              : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
                                          width: 1.5,
                                        ),
                                        boxShadow: isMember
                                            ? [
                                                BoxShadow(
                                                  color: brandPrimary.withValues(alpha: 0.35),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 1.5),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: isMember
                                          ? Icon(
                                              CupertinoIcons.checkmark,
                                              size: 13,
                                              color: isDark ? const Color(0xFF1A1A1A) : CupertinoColors.white,
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

                  const SizedBox(height: 8),

                  // Inline New Collection Creation
                  if (_isCreatingInline) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _newCollectionController,
                              placeholder: 'Collection name...',
                              autofocus: true,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: brandPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF1A1A1A) : CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isCreatingInline = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                              blurRadius: 5,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.plus_circle_fill,
                              size: 18,
                              color: brandPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'New Collection',
                              style: LTypography.body.rounded.copyWith(
                                color: brandPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
