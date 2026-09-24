import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class PlaceEntityCard extends StatelessWidget {
  final String name;
  final String location;
  final String? notesSummary;
  final VoidCallback? onTap;

  const PlaceEntityCard({
    super.key,
    required this.name,
    required this.location,
    this.notesSummary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard.obsidian(
      borderRadius: LSpacing.radiusLG + 2,
      padding: const EdgeInsets.all(LSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map-style header
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C3A), Color(0xFF06231B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: LSpacing.brSM,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.map_pin,
                    size: 13,
                    color: LColors.staticWhite,
                  ),
                  const SizedBox(width: LSpacing.xs),
                  Flexible(
                    child: Text(
                      location,
                      style: LTypography.caption1Bold.copyWith(
                        color: LColors.staticWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: LSpacing.md - 2),
          Text(
            name,
            style: LTypography.footnoteSemibold.copyWith(
              color: LColors.staticWhite,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (notesSummary != null) ...[
            const SizedBox(height: LSpacing.xs - 1),
            Text(
              notesSummary!,
              style: LTypography.caption2.copyWith(color: LColors.staticWhite70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
