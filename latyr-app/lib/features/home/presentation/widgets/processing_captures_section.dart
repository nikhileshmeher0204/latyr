import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class ProcessingCapturesSection extends ConsumerWidget {
  final List<LocalCapture> captures;
  final VoidCallback? onOpenFeed;

  const ProcessingCapturesSection({
    super.key,
    required this.captures,
    this.onOpenFeed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (captures.isEmpty) return const SizedBox.shrink();

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeCaptures = captures
        .where((c) => c.status == 'PROCESSING' || c.status == 'PENDING_SYNC')
        .toList();
    final recentCaptures =
        activeCaptures.isNotEmpty ? activeCaptures : captures.take(3).toList();

    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Captures status',
                  style: LTypography.headline.rounded.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (activeCaptures.isNotEmpty) ...[
                  const SizedBox(width: LSpacing.sm),
                  // Live indicator pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: LColors.brandAmber.withValues(alpha: 0.14),
                      borderRadius: LSpacing.brPill,
                      border: Border.all(
                        color: LColors.brandAmber.withValues(alpha: 0.28),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: LColors.brandAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: LSpacing.xs),
                        Text(
                          '${activeCaptures.length} active',
                          style: LTypography.caption2Bold.rounded.copyWith(
                            color: LColors.brandAmberDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (onOpenFeed != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenFeed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LSpacing.sm,
                    vertical: LSpacing.xs + 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: LTypography.footnote.copyWith(
                          color: LColors.brandAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 12,
                        color: LColors.brandAmber,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: LSpacing.md - 2),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentCaptures.length,
          separatorBuilder: (context, i) => const SizedBox(height: LSpacing.sm),
          itemBuilder: (context, index) {
            final item = recentCaptures[index];
            return _buildCaptureStatusCard(context, item, isDark, labelColor, secondaryColor);
          },
        ),
      ],
    );
  }

  Widget _buildCaptureStatusCard(
    BuildContext context,
    LocalCapture item,
    bool isDark,
    Color labelColor,
    Color secondaryColor,
  ) {
    final bool isInstagram = item.originalUrl?.contains('instagram.com') ?? false;
    final bool isProcessing = item.status == 'PROCESSING';
    final bool isPendingSync = item.status == 'PENDING_SYNC';
    final bool isFailed = item.status == 'FAILED';
    final bool isCompleted = item.status == 'COMPLETED';

    final iconBg = isInstagram
        ? LColors.instagramPink.withValues(alpha: 0.12)
        : LColors.royalIndigo.withValues(alpha: 0.12);
    final iconColor = isInstagram ? LColors.instagramPink : LColors.royalIndigo;

    return GlassCard(
      borderRadius: LSpacing.radiusMD + 2,
      onTap: onOpenFeed,
      padding: const EdgeInsets.symmetric(
        horizontal: LSpacing.md + 2,
        vertical: LSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Source Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: LSpacing.brSM,
            ),
            child: Center(
              child: Icon(
                isInstagram
                    ? CupertinoIcons.play_circle_fill
                    : CupertinoIcons.link,
                size: 20,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: LSpacing.md),

          // Title / Caption / URL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.originalCaption?.isNotEmpty == true
                      ? item.originalCaption!
                      : (item.originalUrl ?? 'Capture item'),
                  style: LTypography.footnote.rounded.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (item.category != null && item.category!.isNotEmpty) ...[
                      Text(
                        item.category!,
                        style: LTypography.caption2.copyWith(
                          color: secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: LTypography.caption2.copyWith(color: secondaryColor),
                      ),
                    ],
                    Text(
                      _formatDate(item.createdAt),
                      style: LTypography.caption2.copyWith(
                        color: isDark
                            ? const Color(0xFF636366)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: LSpacing.sm),

          // Status Badge
          _buildStatusPill(isProcessing, isPendingSync, isFailed, isCompleted),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    bool isProcessing,
    bool isPendingSync,
    bool isFailed,
    bool isCompleted,
  ) {
    if (isProcessing) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LSpacing.md - 2,
          vertical: LSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: LColors.info.withValues(alpha: 0.12),
          borderRadius: LSpacing.brXS,
          border: Border.all(color: LColors.info.withValues(alpha: 0.28), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 5, color: LColors.info),
            const SizedBox(width: LSpacing.xs + 2),
            Text(
              'Analyzing',
              style: LTypography.caption2Bold.copyWith(color: LColors.info),
            ),
          ],
        ),
      );
    }

    if (isPendingSync) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LSpacing.md - 2,
          vertical: LSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: LColors.brandAmber.withValues(alpha: 0.12),
          borderRadius: LSpacing.brXS,
          border: Border.all(color: LColors.brandAmber.withValues(alpha: 0.28), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: LColors.brandAmber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LSpacing.xs + 2),
            Text(
              'Pending',
              style: LTypography.caption2Bold.copyWith(color: LColors.brandAmberDark),
            ),
          ],
        ),
      );
    }

    if (isFailed) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LSpacing.sm,
          vertical: LSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: LColors.error.withValues(alpha: 0.12),
          borderRadius: LSpacing.brXS,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 12,
              color: LColors.error,
            ),
            const SizedBox(width: LSpacing.xs),
            Text(
              'Failed',
              style: LTypography.caption2Bold.copyWith(color: LColors.error),
            ),
          ],
        ),
      );
    }

    // Completed: declutter and hide badge
    return const SizedBox.shrink();
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
