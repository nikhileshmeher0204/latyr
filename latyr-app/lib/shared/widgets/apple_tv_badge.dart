import 'package:flutter/material.dart';

enum AppleTvBadgeVariant { outline, solid }

/// An Apple TV styled monochrome badge (similar to 4K, CC, SDH, Dolby badges).
/// Features a crisp rounded-rect (4px radius), subtle monochrome borders,
/// and uppercase typography with optional leading icon/emoji.
class AppleTvBadge extends StatelessWidget {
  const AppleTvBadge({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.variant = AppleTvBadgeVariant.outline,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    this.fontSize = 10,
  });

  final String label;
  final IconData? icon;
  final String? emoji;
  final AppleTvBadgeVariant variant;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isSolid = variant == AppleTvBadgeVariant.solid;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isSolid
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.45),
        border: Border.all(
          color: isSolid
              ? Colors.white
              : Colors.white.withValues(alpha: 0.4),
          width: 0.9,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (emoji != null) ...[
            Text(
              emoji!,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 3),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: fontSize + 1,
              color: isSolid ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSolid ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
