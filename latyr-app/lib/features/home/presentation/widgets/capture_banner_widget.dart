import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class CaptureBannerWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CaptureBannerWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard.obsidian(
      borderRadius: LSpacing.radiusXL,
      padding: const EdgeInsets.all(LSpacing.base),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share anything. Forget nothing.',
                  style: LTypography.headline.rounded.copyWith(
                    color: LColors.staticWhite,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: LSpacing.xs),
                Text(
                  'Videos, links or screenshots to Latyr — captured automatically.',
                  style: LTypography.caption1.copyWith(
                    height: 1.4,
                    color: LColors.staticWhite70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LSpacing.md),
          // SF-symbol-like sparkle icon container
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: LColors.brandAmber.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: LColors.brandAmber.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.sparkles,
                size: 17,
                color: LColors.brandAmberLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
