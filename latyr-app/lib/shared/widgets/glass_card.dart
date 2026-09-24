import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';

enum GlassCardVariant { light, obsidian }

/// Adaptive frosted-glass card — the primary surface component in Latyr.
///
/// In light mode: warm translucent white over the alabaster background.
/// In dark mode: elevated obsidian glass with subtle white border.
///
/// The press animation (scale 0.97, 140ms) matches Apple's UIKit button response.
class GlassCard extends StatefulWidget {
  final Widget child;
  final GlassCardVariant variant;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Border? customBorder;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.variant = GlassCardVariant.light,
    this.borderRadius = LSpacing.radiusXL,
    this.padding,
    this.margin,
    this.onTap,
    this.customBorder,
    this.width,
    this.height,
  });

  const GlassCard.obsidian({
    super.key,
    required this.child,
    this.borderRadius = LSpacing.radiusXL,
    this.padding,
    this.margin,
    this.onTap,
    this.customBorder,
    this.width,
    this.height,
  }) : variant = GlassCardVariant.obsidian;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Apple UIKit press feedback: 140ms critically-damped spring (no overshoot)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isObsidian = widget.variant == GlassCardVariant.obsidian;

    // Adaptive glass colors
    Color bgColor;
    Color defaultBorderColor;

    if (isObsidian) {
      // Always-dark editorial card (For You, Capture Banner)
      bgColor = const Color(0xE0121316); // 88% obsidian
      defaultBorderColor = const Color(0x1AFFFFFF); // 10% white
    } else if (isDark) {
      bgColor = const Color(0xCC1F1F23); // 80% elevated dark
      defaultBorderColor = const Color(0x1AFFFFFF); // 10% white
    } else {
      bgColor = const Color(0xCCFFFFFF); // 80% white
      defaultBorderColor = const Color(0xA0FFFFFF); // 63% white
    }

    final border = widget.customBorder ?? Border.all(color: defaultBorderColor, width: 0.5);

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: LSpacing.blurCard, sigmaY: LSpacing.blurCard),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(LSpacing.base),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Color(isObsidian
                      ? 0x47000000
                      : (isDark ? 0x59000000 : 0x0D000000)),
                  blurRadius: isObsidian ? 32 : 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: card,
        ),
      );
    }

    return card;
  }
}
