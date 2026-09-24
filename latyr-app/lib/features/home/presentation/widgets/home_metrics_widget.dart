import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class HomeMetricsWidget extends StatelessWidget {
  final int processedCount;
  final int processingCount;
  final int totalInQueue;
  final VoidCallback? onProcessingTap;

  const HomeMetricsWidget({
    super.key,
    required this.processedCount,
    required this.processingCount,
    required this.totalInQueue,
    this.onProcessingTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActivelyProcessing = processingCount > 0 || totalInQueue > 0;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final iconBgEmerald = isDark ? const Color(0x2210B981) : const Color(0xFFEDF7F3);
    final iconBgAmber = isDark ? const Color(0x2AE58B04) : const Color(0x1AE58B04);
    final iconBgIdle = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEDECEA);

    return Row(
      children: [
        // ── 1. Captures Processed Card ──────────────────────────────────────
        Expanded(
          child: GlassCard(
            borderRadius: LSpacing.radiusLG,
            padding: const EdgeInsets.symmetric(
              horizontal: LSpacing.md + 2,
              vertical: LSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgEmerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 18,
                      color: LColors.sageEmerald,
                    ),
                  ),
                ),
                const SizedBox(width: LSpacing.md - 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$processedCount',
                        style: LTypography.largeNumber.copyWith(
                          color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Processed',
                        style: LTypography.caption2.copyWith(
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: LSpacing.md - 2),

        // ── 2. Queue / Processing Card ──────────────────────────────────────
        Expanded(
          child: GlassCard(
            borderRadius: LSpacing.radiusLG,
            onTap: onProcessingTap,
            padding: const EdgeInsets.symmetric(
              horizontal: LSpacing.md + 2,
              vertical: LSpacing.md,
            ),
            customBorder: isActivelyProcessing
                ? Border.all(
                    color: LColors.brandAmber.withValues(alpha: 0.40),
                    width: 0.8,
                  )
                : null,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActivelyProcessing ? iconBgAmber : iconBgIdle,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isActivelyProcessing
                        ? const CupertinoActivityIndicator(
                            radius: 8,
                            color: LColors.brandAmber,
                          )
                        : Icon(
                            CupertinoIcons.clock,
                            size: 17,
                            color: isDark
                                ? const Color(0xFF636366)
                                : const Color(0xFF94A3B8),
                          ),
                  ),
                ),
                const SizedBox(width: LSpacing.md - 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isActivelyProcessing
                            ? '$processingCount / $totalInQueue'
                            : '0',
                        style: LTypography.largeNumber.copyWith(
                          color: isActivelyProcessing
                              ? LColors.brandAmberDark
                              : (isDark
                                  ? const Color(0xFFF5F5F7)
                                  : const Color(0xFF121316)),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isActivelyProcessing ? 'In queue' : 'Idle queue',
                        style: LTypography.caption2.copyWith(
                          color: isActivelyProcessing
                              ? LColors.brandAmberDark
                              : (isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6D7A)),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
