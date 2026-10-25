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
  final bool showBackButton;
  final List<Widget>? actions;
  final bool isDark;
  final Color scaffoldBgColor;
  final bool enableBlur;
  final bool isPersistent;

  /// Standard navigation geometry constants
  static const double kActionButtonSize = 42.0;
  static const double kActionPillWidth = 56.0;
  static const double kActionSpacing = 8.0;
  static const double kMandatoryNavClearance = 14.0;
  static const double kPillHorizontalMargin = 120.0;

  const LatyrAppBar({
    super.key,
    required this.title,
    this.titleLeading,
    this.onBack,
    this.backIcon = CupertinoIcons.back,
    this.showBackButton = true,
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

  /// Builds the inner content of the category pill (leading icon + uppercase label).
  static Widget _buildPillInnerRow({
    required String title,
    Widget? leading,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading,
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
        if (i > 0) renderedActions.add(const SizedBox(width: kActionSpacing));
        renderedActions.add(actions![i]);
      }
    } else {
      renderedActions.add(const SizedBox(width: kActionButtonSize));
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: kActionButtonSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Centered Contextual Bubble Pill with Guaranteed >=12px Clearance
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (actions != null && actions!.length > 1)
                      ? kPillHorizontalMargin
                      : (showBackButton || (actions != null && actions!.isNotEmpty) ? 68.0 : 48.0),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    child: _buildPillInnerRow(
                      title: title,
                      leading: titleLeading,
                      textColor: textColor,
                    ),
                  ),
                ),
              ),

              // 2. Left Back Button (42x42)
              if (showBackButton)
                Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  child: Container(
                    width: kActionButtonSize,
                    height: kActionButtonSize,
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
  /// while smoothly cross-fading foreground content and animating action button shifts.
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
      final canAnimateRightCluster = fromBar.actions != null &&
          toBar.actions != null &&
          fromBar.actions!.length == 2 &&
          toBar.actions!.length == 2;

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

                    // 2. Foreground navigation content:
                    if (canAnimateRightCluster)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildSeamlessFlightContent(
                          context: flightContext,
                          fromBar: fromBar,
                          toBar: toBar,
                          t: t,
                          isDark: isDark,
                        ),
                      )
                    else ...[
                      // Fallback for screens with arbitrary or asymmetric actions
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

  /// Builds seamless flight content where:
  /// - The Category Pill remains anchored and centered while its text/icon dissolves.
  /// - The Back button remains locked at left: 0.
  /// - Action 1 smoothly morphs its width (56px <-> 42px) with cross-fading icon content.
  /// - Action 0 (Share button) glides horizontally without ghosting or double-rendering.
  static Widget _buildSeamlessFlightContent({
    required BuildContext context,
    required LatyrAppBar fromBar,
    required LatyrAppBar toBar,
    required double t,
    required bool isDark,
  }) {
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    // 1. Back button stays 100% stationary at left: 0
    final backButton = Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: kActionButtonSize,
        height: kActionButtonSize,
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
        child: Icon(toBar.backIcon, color: textColor, size: 20),
      ),
    );

    // 2. Centered Contextual Bubble Pill: Container is steady, content smoothly cross-fades
    final pill = Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPillHorizontalMargin),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (t < 1.0)
                Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: _buildPillInnerRow(
                    title: fromBar.title,
                    leading: fromBar.titleLeading,
                    textColor: textColor,
                  ),
                ),
              if (t > 0.0)
                Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: _buildPillInnerRow(
                    title: toBar.title,
                    leading: toBar.titleLeading,
                    textColor: textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // 3. Right Action Cluster with Animated Width Morphing:
    // Action 0: Share button (42px)
    // Gap: 8px
    // Action 1: Morphing width from fromW to toW (e.g. 56px <-> 42px)
    double getActionWidth(Widget action) {
      if (action is LatyrActionPill) return action.width;
      if (action is LatyrActionButton) return action.width;
      return kActionButtonSize;
    }

    final fromW1 = getActionWidth(fromBar.actions![1]);
    final toW1 = getActionWidth(toBar.actions![1]);
    final currentW1 = (fromW1 + (toW1 - fromW1) * t).clamp(kActionButtonSize, kActionPillWidth);

    Widget extractInnerContent(Widget action) {
      if (action is LatyrActionPill) return action.child;
      if (action is LatyrActionButton) return action.child;
      return action;
    }

    final fromAction0Content = extractInnerContent(fromBar.actions![0]);
    final toAction0Content = extractInnerContent(toBar.actions![0]);
    final fromAction1Content = extractInnerContent(fromBar.actions![1]);
    final toAction1Content = extractInnerContent(toBar.actions![1]);

    final rightCluster = Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action 0: Single persistent button (Share) smoothly shifting horizontally as Action 1 changes width
          Container(
            width: kActionButtonSize,
            height: kActionButtonSize,
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
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (t < 1.0)
                    Opacity(
                      opacity: (1.0 - t).clamp(0.0, 1.0),
                      child: fromAction0Content,
                    ),
                  if (t > 0.0)
                    Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: toAction0Content,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: kActionSpacing),
          // Action 1: Morphing capsule/circular button
          Container(
            width: currentW1,
            height: kActionButtonSize,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(kActionButtonSize / 2),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kActionButtonSize / 2),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (t < 1.0)
                      Opacity(
                        opacity: (1.0 - t).clamp(0.0, 1.0),
                        child: fromAction1Content,
                      ),
                    if (t > 0.0)
                      Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: toAction1Content,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: kActionButtonSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              pill,
              backButton,
              rightCluster,
            ],
          ),
        ),
      ),
    );
  }

  /// Helper factory for uniform 42x42 circular frosted action buttons.
  static Widget actionButton({
    required Widget child,
    required VoidCallback onPressed,
    required bool isDark,
    double width = kActionButtonSize,
    double height = kActionButtonSize,
  }) {
    return LatyrActionButton(
      onPressed: onPressed,
      isDark: isDark,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Helper factory for uniform frosted capsule / pill action buttons (e.g. source deeplink with right arrow).
  static Widget actionPill({
    required Widget child,
    required VoidCallback onPressed,
    required bool isDark,
    double width = kActionPillWidth,
    double height = kActionButtonSize,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8),
  }) {
    return LatyrActionPill(
      onPressed: onPressed,
      isDark: isDark,
      width: width,
      height: height,
      padding: padding,
      child: child,
    );
  }
}

/// Uniform circular frosted action button widget.
class LatyrActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool isDark;
  final double width;
  final double height;

  const LatyrActionButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.isDark,
    this.width = LatyrAppBar.kActionButtonSize,
    this.height = LatyrAppBar.kActionButtonSize,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: width,
        height: height,
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

/// Uniform frosted capsule / pill action button widget.
class LatyrActionPill extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool isDark;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const LatyrActionPill({
    super.key,
    required this.child,
    required this.onPressed,
    required this.isDark,
    this.width = LatyrAppBar.kActionPillWidth,
    this.height = LatyrAppBar.kActionButtonSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(height / 2),
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
