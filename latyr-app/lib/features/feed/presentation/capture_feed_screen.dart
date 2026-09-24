import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/feed/presentation/widgets/capture_card_widget.dart';

class CaptureFeedScreen extends ConsumerStatefulWidget {
  const CaptureFeedScreen({super.key});

  @override
  ConsumerState<CaptureFeedScreen> createState() => _CaptureFeedScreenState();
}

class _CaptureFeedScreenState extends ConsumerState<CaptureFeedScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Entertainment',
    'Technology',
    'Food',
    'Places',
    'Books',
  ];

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

          // ── Category Filter Pills ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: LSpacing.sm),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH),
                  itemCount: _categories.length,
                  separatorBuilder: (context, i) => const SizedBox(width: LSpacing.sm),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: LSpacing.base,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? LColors.brandAmber : chipBg,
                          borderRadius: LSpacing.brPill,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: LTypography.subhead.copyWith(
                              color: isSelected ? LColors.staticWhite : secondaryColor,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Captures List / Feed ──────────────────────────────────────────
          capturesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $err', style: LTypography.footnote.copyWith(color: LColors.error)),
              ),
            ),
            data: (captures) {
              final filtered = _selectedCategory == 'All'
                  ? captures
                  : captures.where((c) {
                      final cat = c.category?.toLowerCase() ?? '';
                      final selected = _selectedCategory.toLowerCase();
                      if (selected == 'technology' && (cat == 'tech' || cat == 'technology')) return true;
                      return cat == selected;
                    }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(isDark, labelColor, secondaryColor),
                );
              }

              final feedItems = _buildFeedItems(filtered);

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LSpacing.screenH,
                  LSpacing.xs,
                  LSpacing.screenH,
                  LSpacing.xl3,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = feedItems[index];
                      if (item is _SectionHeaderFeedItem) {
                        return _buildSectionHeader(
                          title: item.title,
                          count: item.count,
                          isFirst: item.isFirst,
                          isDark: isDark,
                          labelColor: labelColor,
                          secondaryColor: secondaryColor,
                          chipBg: chipBg,
                        );
                      } else if (item is _CaptureCardFeedItem) {
                        return _buildTimelineCard(
                          capture: item.capture,
                          isDark: isDark,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: feedItems.length,
                  ),
                ),
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

  List<_FeedItem> _buildFeedItems(List<LocalCapture> captures) {
    final sorted = List<LocalCapture>.from(captures)
      ..sort((a, b) => _getEffectiveTimestamp(b).compareTo(_getEffectiveTimestamp(a)));

    final now = DateTime.now();
    final Map<String, List<LocalCapture>> grouped = {};
    for (final capture in sorted) {
      final key = _getTimelineGroup(_getEffectiveTimestamp(capture), now);
      grouped.putIfAbsent(key, () => []).add(capture);
    }

    final List<_FeedItem> items = [];
    bool isFirstGroup = true;
    grouped.forEach((title, groupCaptures) {
      items.add(_SectionHeaderFeedItem(
        title: title,
        count: groupCaptures.length,
        isFirst: isFirstGroup,
      ));
      isFirstGroup = false;

      for (final capture in groupCaptures) {
        items.add(_CaptureCardFeedItem(capture: capture));
      }
    });

    return items;
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Center(
              child: Container(
                width: 2,
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFD8D8DC),
              ),
            ),
          ),
          const SizedBox(width: LSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: LSpacing.md),
              child: CaptureCardWidget(
                key: ValueKey(capture.id),
                capture: capture,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

sealed class _FeedItem {}

class _SectionHeaderFeedItem extends _FeedItem {
  final String title;
  final int count;
  final bool isFirst;
  _SectionHeaderFeedItem({
    required this.title,
    required this.count,
    required this.isFirst,
  });
}

class _CaptureCardFeedItem extends _FeedItem {
  final LocalCapture capture;
  _CaptureCardFeedItem({required this.capture});
}
