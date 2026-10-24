import 'package:flutter/cupertino.dart';
import 'package:latyr_app/config/app_properties.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/widgets/latyr_progressive_blur.dart';

/// Tag used to coordinate the persistent navigation bar across detail screens.
const String kLatyrPersistentAppBarHeroTag = 'latyr_persistent_app_bar_hero';

/// Canonical, production-ready custom AppBar for Latyr.
///
/// Features:
/// 1. Stationary, persistent navigation physics: When pushing from CaptureDetail
///    to IntentDetail (e.g. Movies, GitHub, Travel), the AppBar stays completely
///    stationary while only the content slides underneath.
/// 2. Progressive Frosted Glass Blur Backdrop (`LatyrProgressiveBlur`) with
///    customizable tint gradients and safety padding.
/// 3. Unified 42x42 circular frosted navigation buttons (back and action cluster).
/// 4. Centered contextual bubble pill with smooth text/icon cross-fading.
class LatyrAppBar extends StatelessWidget {
  final String title;
  final Widget? titleLeading;
  final VoidCallback? onBack;
  final IconData backIcon;
  final List<Widget>? actions;
  final bool isDark;
  final Color scaffoldBgColor;
  final bool enableBlur;
  final bool isPersistent;

  const LatyrAppBar({
    super.key,
    required this.title,
    this.titleLeading,
    this.onBack,
    this.backIcon = CupertinoIcons.back,
    this.actions,
    required this.isDark,
    required this.scaffoldBgColor,
    this.enableBlur = true,
    this.isPersistent = true,
  });

  /// The standard height of the Latyr AppBar including the top safe area inset.
  static double preferredHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 58.0 + 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final navWidget = _buildRawBar(context);

    if (!isPersistent) {
      return navWidget;
    }

    return Hero(
      tag: kLatyrPersistentAppBarHeroTag,
      flightShuttleBuilder: _buildFlightShuttle,
      placeholderBuilder: (context, heroSize, child) => SizedBox(
        width: heroSize.width,
        height: heroSize.height,
      ),
      child: navWidget,
    );
  }

  Widget _buildRawBar(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final navBarHeight = topPadding + 58.0;

    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    return SizedBox(
      height: navBarHeight + 10.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Progressive Frosted Blur Backdrop
          if (enableBlur && (AppProperties.enableTopBlur || AppProperties.enableTopTint))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: navBarHeight + 10.0,
              child: IgnorePointer(
                child: LatyrProgressiveBlur(
                  enabled: AppProperties.enableTopBlur,
                  sigmaStart: 25.0,
                  sigmaEnd: 0.0,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  child: AppProperties.enableTopTint
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.45, 0.80, 1.0],
                              colors: [
                                scaffoldBgColor.withValues(alpha: isDark ? 0.85 : 0.82),
                                scaffoldBgColor.withValues(alpha: isDark ? 0.60 : 0.50),
                                scaffoldBgColor.withValues(alpha: isDark ? 0.20 : 0.12),
                                scaffoldBgColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),

          // 2. Floating Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back Button (Stationary across persistent routes)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(backIcon, color: textColor, size: 20),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Centered Contextual Bubble Pill
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: borderColor,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (titleLeading != null) ...[
                                titleLeading!,
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: LTypography.footnoteSemibold.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: textColor,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right Actions Cluster
                    if (actions != null && actions!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    else
                      const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Custom flight shuttle that holds the back button and blur stationary while
  /// smoothly cross-fading the title pill and action buttons.
  Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    Widget extractChild(BuildContext heroContext) {
      final widget = heroContext.widget;
      if (widget is Hero) {
        return widget.child;
      }
      return widget;
    }

    final fromChild = extractChild(fromHeroContext);
    final toChild = extractChild(toHeroContext);

    // If either child is an empty placeholder, return the non-empty one directly
    final isFromEmpty = fromChild is SizedBox && fromChild.child == null;
    final isToEmpty = toChild is SizedBox && toChild.child == null;

    if (isFromEmpty && isToEmpty) {
      return const SizedBox.shrink();
    }
    if (isFromEmpty) {
      return toChild;
    }
    if (isToEmpty) {
      return fromChild;
    }

    // Use curved animation for natural, fluid iOS timing
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        return IgnorePointer(
          child: Directionality(
            textDirection: Directionality.maybeOf(flightContext) ?? TextDirection.ltr,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                if (t < 1.0)
                  Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: fromChild,
                  ),
                if (t > 0.0)
                  Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: toChild,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper factory for uniform 42x42 circular frosted action buttons.
  static Widget actionButton({
    required Widget child,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cardBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
