import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';
import 'package:latyr_app/shared/widgets/pill_badge.dart';
import 'package:latyr_app/shared/widgets/pill_button.dart';

class ForYouCardWidget extends StatelessWidget {
  final String categoryTag;
  final String title;
  final String subtitle;
  final String? posterUrl;
  final VoidCallback onOpen;

  const ForYouCardWidget({
    super.key,
    required this.categoryTag,
    required this.title,
    required this.subtitle,
    this.posterUrl,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: LSpacing.radiusXL + 2,
      padding: const EdgeInsets.all(LSpacing.md),
      onTap: onOpen,
      child: Row(
        children: [
          // Poster / Thumbnail Box
          Container(
            width: 52,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LColors.terracottaDark, Color(0xFF451016)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: LSpacing.brMD,
              boxShadow: [
                BoxShadow(
                  color: LColors.terracottaDark.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.play_fill,
                color: LColors.staticWhite,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: LSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PillBadge(
                  label: categoryTag,
                  variant: PillBadgeVariant.amber,
                ),
                const SizedBox(height: LSpacing.xs),
                Text(
                  title,
                  style: LTypography.footnoteSemibold.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: LTypography.caption2.copyWith(
                    color: const Color(0xFF8E8E93),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Open Button
          PillButton(
            text: 'Open',
            height: 32,
            variant: PillButtonVariant.solidAmber,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
