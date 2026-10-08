import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class QuoteEntityCard extends StatelessWidget {
  final String quoteText;
  final String? authorOrAttribution;
  final VoidCallback? onTap;

  const QuoteEntityCard({
    super.key,
    required this.quoteText,
    this.authorOrAttribution,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard.obsidian(
      borderRadius: LSpacing.radiusLG + 2,
      padding: const EdgeInsets.all(LSpacing.base),
      customBorder: Border.all(color: LColors.amberBorder, width: 0.8),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amber quotation glyph
          Text(
            '"',
            style: LTypography.largeTitle.copyWith(
              fontFamily: 'serif',
              fontSize: 32,
              height: 0.8,
              fontWeight: FontWeight.w900,
              color: LColors.brandAmber,
            ),
          ),
          const SizedBox(height: LSpacing.sm),

          // Quote Text
          Text(
            quoteText,
            style: LTypography.footnoteSemibold.copyWith(
              color: LColors.staticWhite,
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),

          // Attribution
          if (authorOrAttribution != null) ...[
            const SizedBox(height: LSpacing.md - 2),
            Text(
              authorOrAttribution!,
              style: LTypography.caption2Bold.rounded.copyWith(
                color: LColors.brandAmberLight.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
