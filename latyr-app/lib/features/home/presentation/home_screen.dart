import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/config/app_properties.dart';
import 'package:latyr_app/core/widgets/latyr_progressive_blur.dart';
import 'package:latyr_app/core/widgets/latyr_capture_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/home/presentation/home_providers.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/features/feed/presentation/screens/capture_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CupertinoColors.black : const Color(0xFFF9F9F9);
    final topPadding = MediaQuery.of(context).padding.top;
    final topBlurHeight = topPadding + 14.0;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      child: Stack(
        children: [
          SoftEdgeBlur(
            edges: [
              EdgeBlur(
                type: EdgeType.bottomEdge,
                size: 150,
                sigma: 50,
                controlPoints: [
                  ControlPoint(position: 0.0, type: ControlPointType.visible),
                  ControlPoint(
                    position: 1.0,
                    type: ControlPointType.transparent,
                  ),
                ],
              ),
            ],
            child: RefreshIndicator(
              onRefresh: () async {
                
                await ref.read(captureRepositoryProvider).fetchRemoteFeed();
              },
              color: const Color(0xFF28543A), // Latyr green
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: LSpacing.screenH,
                      right: LSpacing.screenH,
                      top: MediaQuery.of(context).padding.top + LSpacing.md,
                      bottom: LSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context, isDark),
                        const SizedBox(height: LSpacing.xl),
                        _buildDateAndWeather(context, ref, isDark),
                        const SizedBox(height: LSpacing.xl),
                        _buildStatCards(context, ref, isDark),
                        const SizedBox(height: LSpacing.xl),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildOverlappingFeed(context, ref, isDark),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ), // Close RefreshIndicator
          ), // Close SoftEdgeBlur

          // High-Performance Progressive Frosted Blur Backdrop
          if (AppProperties.enableTopBlur || AppProperties.enableTopTint)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topBlurHeight,
              child: IgnorePointer(
                child: LatyrProgressiveBlur(
                  enabled: AppProperties.enableTopBlur,
                  sigmaStart: 20.0,
                  sigmaEnd: 0.0,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  child: AppProperties.enableTopTint
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.50, 0.85, 1.0],
                              colors: [
                                bgColor.withValues(alpha: isDark ? 0.88 : 0.85),
                                bgColor.withValues(alpha: isDark ? 0.65 : 0.55),
                                bgColor.withValues(alpha: isDark ? 0.20 : 0.15),
                                bgColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),

          _buildFloatingActionBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    final btnBg = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final iconColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.book, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                'All Captures',
                style: LTypography.caption1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildCircleButton(
              CupertinoIcons.suit_heart_fill,
              CupertinoColors.systemPink,
              btnBg,
              isDark,
            ),
            const SizedBox(width: 8),
            _buildCircleButton(
              CupertinoIcons.settings,
              textColor,
              btnBg,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    Color iconColor,
    Color btnBg,
    bool isDark,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: btnBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }

  Widget _buildDateAndWeather(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final weatherAsync = ref.watch(weatherProvider);
    final now = DateTime.now();
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _getMonthFull(now.month),
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 42,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getWeekday(now.weekday),
                  style: LTypography.caption1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
            Text(
              now.day.toString(),
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 42,
                height: 1.0,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
        const Spacer(),
        weatherAsync.when(
          data: (weather) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.sun_min_fill,
                    color: CupertinoColors.systemYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${weather.temperature.toStringAsFixed(0)}°",
                    style: LTypography.footnote.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                weather.city,
                style: LTypography.caption2.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          loading: () => Shimmer.fromColors(
            baseColor: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E5EA),
            highlightColor: isDark
                ? const Color(0xFF3A3A3C)
                : const Color(0xFFF2F2F7),
            child: Container(
              height: 30,
              width: 80,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          error: (e, st) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, WidgetRef ref, bool isDark) {
    final statsAsync = ref.watch(homeStatsProvider);
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              color: isDark ? const Color(0xFF28543A) : const Color(0xFFC7F0D8),
              iconColor: const Color(0xFF2A8A5C),
              icon: CupertinoIcons.paw,
              value: stats.capturesToday.toString(),
              label: "Captures Today",
              chartWidget: _buildSquigglyChart(const Color(0xFF2A8A5C)),
            ),
          ),
          const SizedBox(width: LSpacing.sm),
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              color: isDark ? const Color(0xFF24466B) : const Color(0xFFCBE3FA),
              iconColor: const Color(0xFF3B7FC4),
              icon: CupertinoIcons.person_solid,
              value: stats.categoriesDiscovered.toString(),
              label: "Categories",
              chartWidget: _buildBarChart(const Color(0xFF3B7FC4)),
            ),
          ),
          const SizedBox(width: LSpacing.sm),
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              color: isDark ? const Color(0xFF6B332C) : const Color(0xFFFFD1CC),
              iconColor: const Color(0xFFC75748),
              icon: CupertinoIcons.flame_fill,
              value: stats.processingQueue.toString(),
              label: "Processing",
              chartWidget: _buildRingChart(const Color(0xFFC75748)),
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(child: _buildSkeletonStatCard(isDark)),
          const SizedBox(width: LSpacing.sm),
          Expanded(child: _buildSkeletonStatCard(isDark)),
          const SizedBox(width: LSpacing.sm),
          Expanded(child: _buildSkeletonStatCard(isDark)),
        ],
      ),
      error: (e, st) => const SizedBox(),
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String value,
    required String label,
    required Widget chartWidget,
  }) {
    final borderColor = isDark
        ? const Color(0xFF2C2C2E)
        : CupertinoColors.white;
    return AspectRatio(
      aspectRatio: 1.15, // Make them shorter (more rectangular/square)
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x33FFFFFF)
                        : CupertinoColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                chartWidget,
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: LTypography.headline.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
                Text(
                  label,
                  style: LTypography.caption2.copyWith(
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquigglyChart(Color color) {
    return SizedBox(
      width: 24,
      height: 16,
      child: CustomPaint(painter: _SquigglyPainter(color)),
    );
  }

  Widget _buildBarChart(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar(color, 6),
        const SizedBox(width: 2),
        _buildBar(color, 12),
        const SizedBox(width: 2),
        _buildBar(color, 8),
        const SizedBox(width: 2),
        _buildBar(color, 16),
      ],
    );
  }

  Widget _buildBar(Color color, double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildRingChart(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
    );
  }

  Widget _buildSkeletonStatCard(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      highlightColor: isDark
          ? const Color(0xFF3A3A3C)
          : const Color(0xFFF2F2F7),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingFeed(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final asyncCaptures = ref.watch(captureListStreamProvider);

    return asyncCaptures.when(
      data: (captures) {
        if (captures.isEmpty) {
          return const Center(child: Text("No captures yet."));
        }
        return StackedFeedCarousel(captures: captures, isDark: isDark);
      },
      loading: () => const SizedBox(
        height: 400,
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, st) => const SizedBox(
        height: 400,
        child: Center(child: Text('Error loading feed')),
      ),
    );
  }

  Widget _buildFloatingActionBar(BuildContext context, bool isDark) {
    return Positioned(
      bottom: 120, // Shifted up to clear the new navigation pill
      right: LSpacing.xl,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            // TODO: trigger quick add
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.pen,
                  size: 18,
                  color: isDark ? CupertinoColors.black : CupertinoColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create a Latyr',
                  style: LTypography.buttonLabel.copyWith(
                    color: isDark
                        ? CupertinoColors.black
                        : CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getWeekday(int w) {
    const map = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return map[w] ?? '';
  }

  String _getMonthFull(int m) {
    const map = {
      1: 'January',
      2: 'February',
      3: 'March',
      4: 'April',
      5: 'May',
      6: 'June',
      7: 'July',
      8: 'August',
      9: 'September',
      10: 'October',
      11: 'November',
      12: 'December',
    };
    return map[m] ?? '';
  }
}

// ---------------------------------------------------------
// Custom Stacked Feed Carousel
// ---------------------------------------------------------
class StackedFeedCarousel extends StatefulWidget {
  final List<LocalCapture> captures;
  final bool isDark;

  const StackedFeedCarousel({
    super.key,
    required this.captures,
    required this.isDark,
  });

  @override
  State<StackedFeedCarousel> createState() => _StackedFeedCarouselState();
}

class _StackedFeedCarouselState extends State<StackedFeedCarousel> {
  final _pageController = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _page = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort indices so the center card (closest to _page) is drawn LAST (on top)
    List<int> sortedIndices = List.generate(widget.captures.length, (i) => i);
    sortedIndices.sort((a, b) {
      double distA = (a - _page).abs();
      double distB = (b - _page).abs();
      return distB.compareTo(distA);
    });

    return SizedBox(
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative Stickers
          Positioned(
            top: 20,
            left: 30,
            child: _buildStickerIcon(
              CupertinoIcons.cloud_sun_fill,
              CupertinoColors.systemYellow,
              widget.isDark,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 10,
            child: _buildStickerIcon(
              CupertinoIcons.hare_fill,
              CupertinoColors.systemBrown,
              widget.isDark,
            ),
          ),
          Positioned(
            top: 50,
            right: 30,
            child: _buildStickerIcon(
              CupertinoIcons.tree,
              CupertinoColors.systemGreen,
              widget.isDark,
            ),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: _buildStickerIcon(
              CupertinoIcons.sparkles,
              CupertinoColors.systemPurple,
              widget.isDark,
            ),
          ),

          // Stacked cards
          for (int i in sortedIndices) _buildAnimatedCard(i),

          // Transparent PageView to capture swipe gestures and card taps
          PageView.builder(
            controller: _pageController,
            itemCount: widget.captures.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => CaptureDetailScreen(capture: widget.captures[index]),
                  ),
                );
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(int index) {
    double diff = index - _page;
    double absDiff = diff.abs();

    // Only show active and immediately adjacent cards
    if (absDiff >= 2) return const SizedBox.shrink();

    double sign = diff < 0 ? -1 : 1;
    double x = 0;
    double scale = 1.0;
    double angle = 0;
    double opacity = 1.0;

    if (absDiff <= 1) {
      // Interpolate between center (0) and side (1)
      // Side cards are tucked closer to the center card
      x = diff * 95; // Reduced from 120 to 95 to tuck them closer
      scale = 1.0 - (absDiff * 0.15); // scales down to 0.85
      angle = diff * 0.08; // slightly tilted outwards
      opacity = 1.0 - (absDiff * 0.3); // slightly faded
    } else {
      // Interpolate from side (1) to hidden (2)
      double extraDiff = absDiff - 1;
      x = sign * (95 + extraDiff * 80);
      scale = 0.85 - (extraDiff * 0.15);
      angle = sign * (0.08 + extraDiff * 0.04);
      opacity = 0.7 - (extraDiff * 0.7);
    }


    return Positioned(
      key: ValueKey('card_$index'),
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(x, 0), // Centered vertically
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: _buildStackedCard(
                    widget.captures[index],
                    widget.isDark,
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickerIcon(IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStackedCard(LocalCapture capture, bool isDark) {
    return SizedBox(
      width: 220,
      height: 260,
      child: LatyrCaptureCard(capture: capture),
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final Color color;
  _SquigglyPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




