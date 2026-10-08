import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class MetricStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const MetricStatCard({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final defaultValueColor =
        isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final labelColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return Expanded(
      child: GlassCard(
        borderRadius: LSpacing.radiusLG,
        padding: const EdgeInsets.symmetric(
          vertical: LSpacing.md,
          horizontal: LSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: LTypography.roundedNumber.copyWith(
                color: valueColor ?? defaultValueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: LTypography.caption2.rounded.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
