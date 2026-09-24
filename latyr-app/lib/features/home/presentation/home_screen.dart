import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/collections/presentation/collection_detail_screen.dart';
import 'package:latyr_app/features/feed/presentation/capture_feed_screen.dart';
import 'package:latyr_app/features/home/presentation/widgets/capture_banner_widget.dart';
import 'package:latyr_app/features/home/presentation/widgets/for_you_card_widget.dart';
import 'package:latyr_app/features/home/presentation/widgets/home_metrics_widget.dart';
import 'package:latyr_app/features/home/presentation/widgets/library_1x2_grid_widget.dart';
import 'package:latyr_app/features/home/presentation/widgets/processing_captures_section.dart';
import 'package:latyr_app/shared/widgets/ambient_mesh_background.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToLibrary;

  const HomeScreen({
    super.key,
    required this.onNavigateToLibrary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureListAsync = ref.watch(captureListStreamProvider);
    final captures = captureListAsync.valueOrNull ?? [];

    final processedCount = captures.where((c) => c.status == 'COMPLETED').length;
    final processingCount = captures.where((c) => c.status == 'PROCESSING').length;
    final inQueueCount = captures
        .where((c) => c.status == 'PROCESSING' || c.status == 'PENDING_SYNC')
        .length;

    final moviesCount = captures
        .where((c) =>
            (c.category?.toLowerCase().contains('entertainment') ?? false) ||
            (c.category?.toLowerCase().contains('movie') ?? false))
        .length;
    final reposCount = captures
        .where((c) =>
            (c.category?.toLowerCase().contains('developer') ?? false) ||
            (c.category?.toLowerCase().contains('tech') ?? false))
        .length;

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return AmbientMeshBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LSpacing.screenH,
                LSpacing.screenTop,
                LSpacing.screenH,
                LSpacing.navIslandClear,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Greeting + Headline ─────────────────────────────────────
                  Text(
                    _greeting(),
                    style: LTypography.footnote.copyWith(
                      color: secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Everything worth\ncoming back to.',
                    style: LTypography.title1.copyWith(color: labelColor),
                  ),
                  const SizedBox(height: LSpacing.base),

                  // ── 1. Ingestion Metrics ────────────────────────────────────
                  HomeMetricsWidget(
                    processedCount: processedCount,
                    processingCount: processingCount,
                    totalInQueue: inQueueCount,
                    onProcessingTap: () => _pushFeed(context),
                  ),
                  const SizedBox(height: LSpacing.base),

                  // ── 2. Capture Banner ───────────────────────────────────────
                  CaptureBannerWidget(
                    onTap: () => _showQuickCaptureSheet(context, ref),
                  ),
                  const SizedBox(height: LSpacing.lg),

                  // ── 3. In-Progress Captures ─────────────────────────────────
                  if (captures.isNotEmpty) ...[
                    ProcessingCapturesSection(
                      captures: captures,
                      onOpenFeed: () => _pushFeed(context),
                    ),
                    const SizedBox(height: LSpacing.sectionSpacing),
                  ],

                  // ── 4. For You Section ──────────────────────────────────────
                  _SectionHeader(
                    title: 'For you',
                    trailing: 'Resurfaced when it matters',
                    trailingColor: secondaryColor,
                    labelColor: labelColor,
                  ),
                  const SizedBox(height: LSpacing.sectionGap),

                  if (captures.any((c) => c.status == 'COMPLETED'))
                    ForYouCardWidget(
                      categoryTag: captures
                              .firstWhere((c) => c.status == 'COMPLETED')
                              .category ??
                          'Resurfaced',
                      title: captures
                              .firstWhere((c) => c.status == 'COMPLETED')
                              .originalCaption ??
                          captures
                              .firstWhere((c) => c.status == 'COMPLETED')
                              .originalUrl ??
                          'Processed Capture',
                      subtitle: 'Saved from Instagram',
                      onOpen: () => _pushFeed(context),
                    )
                  else
                    _EmptyPlaceholder(
                      message: 'No items yet. Share content to Latyr.',
                      color: secondaryColor,
                    ),
                  const SizedBox(height: LSpacing.sectionSpacing),

                  // ── 5. Your Library Section ─────────────────────────────────
                  _SectionHeader(
                    title: 'Your library',
                    labelColor: labelColor,
                    trailingWidget: GestureDetector(
                      onTap: onNavigateToLibrary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${captures.map((c) => c.category).where((c) => c != null && c.isNotEmpty).toSet().length} collections',
                            style: LTypography.caption1Bold.copyWith(
                              color: LColors.brandAmber,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 12,
                            color: LColors.brandAmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: LSpacing.sectionGap),

                  if (captures.any((c) => c.status == 'COMPLETED'))
                    Library1x2GridWidget(
                      moviesCount: moviesCount,
                      reposCount: reposCount,
                      onMoviesTap: () => _pushMovies(context),
                      onReposTap: onNavigateToLibrary,
                    )
                  else
                    _EmptyPlaceholder(
                      message: 'No collections yet. Share content to Latyr.',
                      color: secondaryColor,
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _pushFeed(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(builder: (_) => const CaptureFeedScreen()),
    );
  }

  void _pushMovies(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => const CollectionDetailScreen(
          title: 'Movies & Shows',
          subtitle: 'All saved films, trailers and watchlist picks.',
        ),
      ),
    );
  }

  void _showQuickCaptureSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAF9F6);
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);
    final inputBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: LSpacing.brSheet,
          ),
          padding: const EdgeInsets.fromLTRB(
            LSpacing.xl,
            LSpacing.lg,
            LSpacing.xl,
            LSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFD1D1D6),
                    borderRadius: LSpacing.brPill,
                  ),
                ),
              ),
              const SizedBox(height: LSpacing.lg),
              Text(
                'Quick Capture',
                style: LTypography.title3.copyWith(color: labelColor),
              ),
              const SizedBox(height: LSpacing.xs),
              Text(
                'Paste any Instagram Reel, Tweet, or web link:',
                style: LTypography.footnote.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: LSpacing.md),
              CupertinoTextField(
                controller: controller,
                autofocus: true,
                placeholder: 'https://instagram.com/reel/...',
                placeholderStyle: LTypography.callout.copyWith(
                  color: const Color(0xFF8E8E93),
                ),
                style: LTypography.callout.copyWith(color: labelColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: LSpacing.md,
                  vertical: LSpacing.md - 2,
                ),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: LSpacing.brMD,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFD1D1D6),
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: LSpacing.base),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: LSpacing.brMD,
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      ref.read(captureRepositoryProvider).captureUrl(text);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    'Capture to Latyr',
                    style: LTypography.buttonLabel.copyWith(
                      color: LColors.staticWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable iOS-style section header with optional trailing text or widget.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color? trailingColor;
  final Color labelColor;
  final Widget? trailingWidget;

  const _SectionHeader({
    required this.title,
    required this.labelColor,
    this.trailing,
    this.trailingColor,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: LTypography.headline.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        ?trailingWidget,
        if (trailing != null && trailingWidget == null)
          Text(
            trailing!,
            style: LTypography.caption2.copyWith(
              color: trailingColor ?? const Color(0xFF8E8E93),
            ),
          ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String message;
  final Color color;

  const _EmptyPlaceholder({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LSpacing.md, horizontal: LSpacing.xs),
      child: Text(
        message,
        style: LTypography.footnote.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
