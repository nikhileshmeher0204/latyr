import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';

enum PillBadgeVariant { amber, terracotta, indigo, emerald, violet, neutral }

/// Small pill-shaped semantic badge — fully adaptive to light/dark mode.
class PillBadge extends StatelessWidget {
  final String label;
  final Widget? icon;
  final PillBadgeVariant variant;
  final VoidCallback? onTap;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = PillBadgeVariant.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    Color bgColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case PillBadgeVariant.amber:
        bgColor = isDark ? const Color(0x2AE58B04) : const Color(0xFFFEF3C7);
        textColor = LColors.brandAmberDark;
        border = Border.all(color: LColors.amberBorder, width: 0.5);
        break;
      case PillBadgeVariant.terracotta:
        bgColor = isDark ? const Color(0x22D9534F) : const Color(0xFFFDF2F0);
        textColor = LColors.terracotta;
        break;
      case PillBadgeVariant.indigo:
        bgColor = isDark ? const Color(0x226366F1) : const Color(0xFFEFF1FF);
        textColor = LColors.royalIndigo;
        break;
      case PillBadgeVariant.emerald:
        bgColor = isDark ? const Color(0x2210B981) : const Color(0xFFEDF7F3);
        textColor = LColors.sageEmerald;
        break;
      case PillBadgeVariant.violet:
        bgColor = isDark ? const Color(0x228B5CF6) : const Color(0xFFF5F3FF);
        textColor = LColors.royalViolet;
        break;
      case PillBadgeVariant.neutral:
        bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEDECEA);
        textColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);
        break;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LSpacing.md - 2,
        vertical: LSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: LSpacing.brPill,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: LSpacing.xs),
          ],
          Text(
            label,
            style: LTypography.caption2Bold.copyWith(color: textColor),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badge);
    }
    return badge;
  }
}
