import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';

enum PillButtonVariant { solidAmber, glass, obsidian }

/// iOS-style pill button with spring press feedback.
///
/// All variants adapt to light/dark mode. Press animation: 140ms scale to 0.96
/// (critically-damped, no overshoot) — matching Apple's UIKit feedback latency.
class PillButton extends StatefulWidget {
  final String text;
  final Widget? icon;
  final VoidCallback onPressed;
  final PillButtonVariant variant;
  final double height;

  const PillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = PillButtonVariant.solidAmber,
    this.height = 36.0,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    Color bgColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case PillButtonVariant.solidAmber:
        bgColor = LColors.brandAmber;
        textColor = LColors.staticWhite;
        shadows = [
          BoxShadow(
            color: LColors.brandAmber.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case PillButtonVariant.obsidian:
        bgColor = const Color(0xFF0E0E10);
        textColor = LColors.staticWhite;
        break;
      case PillButtonVariant.glass:
        bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF).withValues(alpha: 0.75);
        textColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
        border = Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x80FFFFFF),
          width: 0.5,
        );
        break;
    }

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          constraints: BoxConstraints(minWidth: LSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: LSpacing.base),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: LSpacing.brPill,
            border: border,
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: LSpacing.xs + 2),
              ],
              Text(
                widget.text,
                style: LTypography.pillLabel.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
