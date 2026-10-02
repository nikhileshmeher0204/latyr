import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/services/dominant_color_service.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/feed/presentation/widgets/capture_card_widget.dart';

class CaptureFeedScreen extends ConsumerStatefulWidget {
  const CaptureFeedScreen({super.key});

  @override
  ConsumerState<CaptureFeedScreen> createState() => _CaptureFeedScreenState();
}

class _CaptureFeedScreenState extends ConsumerState<CaptureFeedScreen> {
  String _selectedCategory = 'All';
  bool _isGrid = true;



  void _showQuickAddSheet(BuildContext context) {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final labelColor = CupertinoColors.label.resolveFrom(context);
          final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
          final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

          return Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + LSpacing.xl,
              left: LSpacing.screenH,
              right: LSpacing.screenH,
              top: LSpacing.md,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey4.resolveFrom(context),
                        borderRadius: LSpacing.brPill,
                      ),
                    ),
                  ),
                  const SizedBox(height: LSpacing.base),

                  // Title & Cancel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Capture',
                        style: LTypography.title2.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text('Cancel', style: LTypography.body.copyWith(color: LColors.brandAmber)),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: LSpacing.xs),
                  Text(
                    'Paste a public Instagram Reel, YouTube Shorts, or article link.',
                    style: LTypography.footnote.copyWith(color: secondaryColor),
                  ),
                  const SizedBox(height: LSpacing.lg),

                  // Input field
                  CupertinoTextField(
                    controller: textController,
                    autofocus: true,
                    placeholder: 'https://instagram.com/reel/...',
                    placeholderStyle: LTypography.body.copyWith(
                      color: CupertinoColors.placeholderText.resolveFrom(context),
                    ),
                    style: LTypography.body.copyWith(color: labelColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: LSpacing.base,
                      vertical: LSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: LSpacing.brMD,
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                    suffix: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: LSpacing.sm),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          textController.text = data!.text!;
                        }
                      },
                      child: const Icon(CupertinoIcons.doc_on_clipboard, size: 20, color: LColors.brandAmber),
                    ),
                  ),
                  const SizedBox(height: LSpacing.base),

                  // Submit Button
                  CupertinoButton.filled(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final url = textController.text.trim();
                            if (url.isEmpty) return;

                            setModalState(() => isSubmitting = true);
                            try {
                              await ref.read(captureRepositoryProvider).captureUrl(url);
                              if (context.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                            } catch (_) {
                              if (context.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                            }
                          },
                    child: isSubmitting
                        ? const CupertinoActivityIndicator(color: LColors.staticWhite)
                        : const Text('Save & Extract Insights'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capturesAsync = ref.watch(captureListStreamProvider);
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final chipBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          // ── Apple Large Title Nav Bar ─────────────────────────────────────
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Captures'),
            border: null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _isGrid = !_isGrid),
                  child: Icon(
                    _isGrid ? CupertinoIcons.rectangle_grid_1x2 : CupertinoIcons.square_grid_2x2,
                    size: 22,
                    color: LColors.brandAmber,
                  ),
                ),
                const SizedBox(width: LSpacing.xs),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => ref.read(captureRepositoryProvider).fetchRemoteFeed(),
                  child: const Icon(CupertinoIcons.arrow_clockwise, size: 20, color: LColors.brandAmber),
                ),
                const SizedBox(width: LSpacing.xs),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showQuickAddSheet(context),
                  child: const Icon(
                    CupertinoIcons.plus_circle_fill,
                    size: 28,
                    color: LColors.brandAmber,
                  ),
                ),
              ],
            ),
          ),

          // ── Pull-to-refresh ───────────────────────────────────────────────
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(captureRepositoryProvider).fetchRemoteFeed(),
          ),

          capturesAsync.maybeWhen(
            data: (captures) {
              final inProgress = captures
                  .where((c) =>
                      c.status == 'PROCESSING' ||
                      c.status == 'PENDING' ||
                      c.status == 'PENDING_SYNC')
                  .toList();
              if (inProgress.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(LSpacing.screenH, LSpacing.sm, LSpacing.screenH, LSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: LSpacing.base, vertical: LSpacing.md),
                    decoration: BoxDecoration(
                      color: LColors.brandAmber.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: LSpacing.brMD,
                      border: Border.all(color: LColors.brandAmber.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const CupertinoActivityIndicator(radius: 8),
                        const SizedBox(width: LSpacing.base),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Extracting ${inProgress.length} ${inProgress.length == 1 ? 'item' : 'items'}…',
                                style: LTypography.subhead.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: labelColor,
                                ),
                              ),
                              Text(
                                'Analyzing video transcription, entities & highlights',
                                style: LTypography.caption1.copyWith(color: secondaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ── Sticky Category Filter Pills with Liquid Glass ────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryHeaderDelegate(
              categories: [
                {'name': 'All', 'icon': CupertinoIcons.sparkles, 'color': CupertinoColors.systemGrey},
                {'name': 'Entertainment', 'icon': CupertinoIcons.play_rectangle_fill, 'color': CupertinoColors.systemPurple},
                {'name': 'Technology', 'icon': CupertinoIcons.device_laptop, 'color': CupertinoColors.systemBlue},
                {'name': 'Food', 'icon': CupertinoIcons.heart_fill, 'color': CupertinoColors.systemOrange},
                {'name': 'Places', 'icon': CupertinoIcons.location_solid, 'color': CupertinoColors.systemGreen},
                {'name': 'Books', 'icon': CupertinoIcons.book_fill, 'color': CupertinoColors.systemBrown},
              ],
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) {
                setState(() => _selectedCategory = cat);
              },
              isDark: isDark,
              chipBg: chipBg,
              labelColor: labelColor,
              secondaryColor: secondaryColor,
            ),
          ),

          // ── Captures List / Feed ──────────────────────────────────────────
          ...capturesAsync.when(
            loading: () => [
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              ),
            ],
            error: (err, _) => [
              SliverFillRemaining(
                child: Center(
                  child: Text('Error: $err', style: LTypography.footnote.copyWith(color: LColors.error)),
                ),
              ),
            ],
            data: (captures) {
              DominantColorService.instance.warmUp(captures.map((c) => c.thumbnailUrl));
              final filtered = _selectedCategory == 'All'
                  ? captures
                  : captures.where((c) {
                      final cat = c.category?.toLowerCase() ?? '';
                      final selected = _selectedCategory.toLowerCase();
                      if (selected == 'technology' && (cat == 'tech' || cat == 'technology')) return true;
                      return cat == selected;
                    }).toList();

              if (filtered.isEmpty) {
                return [
                  SliverFillRemaining(
                    child: _buildEmptyState(isDark, labelColor, secondaryColor),
                  ),
                ];
              }

              return _buildCaptureSlivers(
                filtered,
                isDark: isDark,
                labelColor: labelColor,
                secondaryColor: secondaryColor,
                chipBg: chipBg,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color labelColor, Color secondaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(LSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.rectangle_stack_badge_plus,
                size: 36,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: LSpacing.base),
            Text(
              'No Captures Yet',
              style: LTypography.title2.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: LSpacing.xs),
            Text(
              'Tap the + button above or share an Instagram Reel to Latyr to start capturing.',
              textAlign: TextAlign.center,
              style: LTypography.footnote.copyWith(color: secondaryColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getEffectiveTimestamp(LocalCapture capture) {
    return capture.updatedAt.isAfter(capture.createdAt)
        ? capture.updatedAt
        : capture.createdAt;
  }

  String _getTimelineGroup(DateTime date, DateTime now) {
    final dateLocal = date.toLocal();
    final nowLocal = now.toLocal();
    final dateDay = DateTime(dateLocal.year, dateLocal.month, dateLocal.day);
    final todayDay = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final diffDays = todayDay.difference(dateDay).inDays;

    if (diffDays <= 0) {
      return 'Today';
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (diffDays > 1 && diffDays <= 7) {
      return 'This Week';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final monthName = months[dateLocal.month - 1];
      return '$monthName ${dateLocal.year}';
    }
  }

  Map<String, List<LocalCapture>> _groupCaptures(List<LocalCapture> captures) {
    final sorted = List<LocalCapture>.from(captures)
      ..sort((a, b) => _getEffectiveTimestamp(b).compareTo(_getEffectiveTimestamp(a)));

    final now = DateTime.now();
    final Map<String, List<LocalCapture>> grouped = {};
    for (final capture in sorted) {
      final key = _getTimelineGroup(_getEffectiveTimestamp(capture), now);
      grouped.putIfAbsent(key, () => []).add(capture);
    }
    return grouped;
  }

  List<Widget> _buildCaptureSlivers(
    List<LocalCapture> captures, {
    required bool isDark,
    required Color labelColor,
    required Color secondaryColor,
    required Color chipBg,
  }) {
    final grouped = _groupCaptures(captures);
    final slivers = <Widget>[];
    bool isFirst = true;

    grouped.forEach((title, groupCaptures) {
      // 1. Section Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH),
            child: _buildSectionHeader(
              title: title,
              count: groupCaptures.length,
              isFirst: isFirst,
              isDark: isDark,
              labelColor: labelColor,
              secondaryColor: secondaryColor,
              chipBg: chipBg,
            ),
          ),
        ),
      );
      isFirst = false;

      // 2. Section Content (2-Column Grid or Single-Column List)
      if (_isGrid) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              LSpacing.screenH,
              0,
              LSpacing.screenH,
              LSpacing.sm,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => CaptureCardWidget(
                  key: ValueKey(groupCaptures[index].id),
                  capture: groupCaptures[index],
                  isGrid: true,
                ),
                childCount: groupCaptures.length,
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTimelineCard(
                  capture: groupCaptures[index],
                  isDark: isDark,
                ),
                childCount: groupCaptures.length,
              ),
            ),
          ),
        );
      }
    });

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: LSpacing.xl3)));
    return slivers;
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required bool isFirst,
    required bool isDark,
    required Color labelColor,
    required Color secondaryColor,
    required Color chipBg,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? LSpacing.xs : LSpacing.xl2,
        bottom: LSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: LColors.brandAmber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: LColors.brandAmber.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: LSpacing.md),
          Expanded(
            child: Text(
              title,
              style: LTypography.title1.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: labelColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: LTypography.caption1.copyWith(
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard({
    required LocalCapture capture,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LSpacing.md),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFD8D8DC),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14 + LSpacing.md),
            child: CaptureCardWidget(
              key: ValueKey(capture.id),
              capture: capture,
              isGrid: false,
            ),
          ),
        ],
      ),
    );
  }
}


class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final bool isDark;
  final Color chipBg;
  final Color labelColor;
  final Color secondaryColor;

  _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.isDark,
    required this.chipBg,
    required this.labelColor,
    required this.secondaryColor,
  });

  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Liquid glass effect for the sticky header background
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: CupertinoColors.systemGroupedBackground
              .resolveFrom(context)
              .withValues(alpha: 0.7), // Transparent base color to let blur show through
          alignment: Alignment.center,
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH),
              itemCount: categories.length,
              separatorBuilder: (context, i) => const SizedBox(width: LSpacing.sm),
              itemBuilder: (context, index) {
                final catData = categories[index];
                final catName = catData['name'] as String;
                final catIcon = catData['icon'] as IconData;
                final catColor = catData['color'] as Color;
                final isSelected = selectedCategory == catName;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onCategorySelected(catName),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: LSpacing.base,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      // Subtle glassy inner background
                      color: isSelected
                          ? LColors.brandAmber
                          : isDark
                              ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
                              : const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                      borderRadius: LSpacing.brPill,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0x00000000)
                            : isDark
                                ? const Color(0x33FFFFFF)
                                : const Color(0x33000000),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          catIcon,
                          size: 16,
                          color: isSelected ? LColors.staticWhite : catColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          catName,
                          style: LTypography.subhead.copyWith(
                            color: isSelected ? LColors.staticWhite : secondaryColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return selectedCategory != oldDelegate.selectedCategory ||
        isDark != oldDelegate.isDark;
  }
}
