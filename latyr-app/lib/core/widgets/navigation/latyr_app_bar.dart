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
      child: _LatyrAppBarWrapper(
        appBar: this,
        child: navWidget,
      ),
    );
  }

  Widget _buildRawBar(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final navBarHeight = topPadding + 58.0;

    return SizedBox(
      height: navBarHeight + 10.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Progressive Frosted Blur Backdrop
          if (enableBlur && (AppProperties.enableTopBlur || AppProperties.enableTopTint))
            _buildBackdrop(context, scaffoldBgColor, isDark),

          // 2. Floating Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildBarContent(context),
          ),
        ],
      ),
    );
  }

  /// Progressive frosted blur & tint gradient backdrop.
  /// Rendered at root level of flight shuttle so blur remains continuously active
  /// without being wrapped in Opacity (which breaks BackdropFilter in Flutter).
  Widget _buildBackdrop(BuildContext context, Color bgColor, bool dark) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final navBarHeight = topPadding + 58.0;

    return Positioned(
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
                        bgColor.withValues(alpha: dark ? 0.85 : 0.82),
                        bgColor.withValues(alpha: dark ? 0.60 : 0.50),
                        bgColor.withValues(alpha: dark ? 0.20 : 0.12),
                        bgColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// Floating Navigation Bar: Back button, Centered Category Pill, and Action Buttons.
  Widget _buildBarContent(BuildContext context) {
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    final renderedActions = <Widget>[];
    if (actions != null && actions!.isNotEmpty) {
      for (int i = 0; i < actions!.length; i++) {
        if (i > 0) renderedActions.add(const SizedBox(width: 8));
        renderedActions.add(actions![i]);
      }
    } else {
      renderedActions.add(const SizedBox(width: 42));
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Centered Contextual Bubble Pill
              Padding(
                padding: const EdgeInsets.only(left: 54, right: 104),
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

              // 2. Left Back Button (42x42)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: CupertinoButton(
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
              ),

              // 3. Right Actions Cluster
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: renderedActions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom flight shuttle that holds the blur backdrop continuously active and stationary
  /// while smoothly cross-fading the foreground navigation content.
  Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    LatyrAppBar? extractAppBar(BuildContext heroContext) {
      final widget = heroContext.widget;
      if (widget is Hero && widget.child is _LatyrAppBarWrapper) {
        return (widget.child as _LatyrAppBarWrapper).appBar;
      }
      return heroContext.findAncestorWidgetOfExactType<LatyrAppBar>();
    }

    final fromBar = extractAppBar(fromHeroContext);
    final toBar = extractAppBar(toHeroContext);

    Widget extractChild(BuildContext heroContext) {
      final widget = heroContext.widget;
      if (widget is Hero) {
        return widget.child;
      }
      return widget;
    }

    final fromChild = extractChild(fromHeroContext);
    final toChild = extractChild(toHeroContext);

    // Normalize transition progress to always go 0.0 -> 1.0 from source to destination.
    // In Flutter, push animation goes 0.0 -> 1.0, while pop animation goes 1.0 -> 0.0.
    final isPop = flightDirection == HeroFlightDirection.pop;
    final progressAnimation = isPop ? ReverseAnimation(animation) : animation;

    // Use curved animation for natural, fluid iOS timing
    final curved = CurvedAnimation(
      parent: progressAnimation,
      curve: Curves.easeInOutCubic,
    );

    // Optimized persistent blur flight shuttle:
    // Render the blur backdrop once at full opacity (NO Opacity widget!),
    // ensuring the fragment shader never breaks or reapplies across transitions.
    if (fromBar != null && toBar != null) {
      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final t = curved.value;
          final blendedBg = Color.lerp(fromBar.scaffoldBgColor, toBar.scaffoldBgColor, t)!;
          final isDark = t > 0.5 ? toBar.isDark : fromBar.isDark;

          return IgnorePointer(
            child: Directionality(
              textDirection: Directionality.maybeOf(flightContext) ?? TextDirection.ltr,
              child: SizedBox(
                height: preferredHeight(flightContext),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Persistent Blur Backdrop: UNINTERRUPTED, NEVER wrapped in Opacity!
                    if (fromBar.enableBlur || toBar.enableBlur)
                      fromBar._buildBackdrop(flightContext, blendedBg, isDark),

                    // 2. Foreground content cross-fade: ONLY buttons & pill are faded
                    if (t < 1.0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: fromBar._buildBarContent(flightContext),
                        ),
                      ),
                    if (t > 0.0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: toBar._buildBarContent(flightContext),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Fallback: Safe raw cross-fade for placeholder / unexpected widget types
    final isFromEmpty = fromChild is SizedBox && fromChild.child == null;
    final isToEmpty = toChild is SizedBox && toChild.child == null;

    if (isFromEmpty && isToEmpty) return const SizedBox.shrink();
    if (isFromEmpty) return toChild;
    if (isToEmpty) return fromChild;

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

/// Internal wrapper preserving a typed reference to the parent [LatyrAppBar]
/// across the Hero widget boundary, enabling the flight shuttle to read properties
/// directly and avoid wrapping the progressive blur in an Opacity layer.
class _LatyrAppBarWrapper extends StatelessWidget {
  final LatyrAppBar appBar;
  final Widget child;

  const _LatyrAppBarWrapper({
    required this.appBar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}
