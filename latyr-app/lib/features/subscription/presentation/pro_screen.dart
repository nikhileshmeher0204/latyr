import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/subscription/presentation/paywall_modal.dart';

class LatyrProScreen extends ConsumerWidget {
  const LatyrProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureListAsync = ref.watch(captureListStreamProvider);
    final captures = captureListAsync.valueOrNull ?? [];
    final completedCount = captures.where((c) => c.status == 'COMPLETED').length;
    final totalLimit = 30;
    final progress = (completedCount / totalLimit).clamp(0.0, 1.0);

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabelColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Latyr Pro'),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH, vertical: LSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Banner ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(LSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2C1E0F), const Color(0xFF1C1C1E)]
                            : [const Color(0xFFFFF7ED), CupertinoColors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: LSpacing.brLG,
                      border: Border.all(
                        color: LColors.brandAmber.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: LColors.brandAmber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.sparkles,
                              color: LColors.brandAmber,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: LSpacing.md),
                        Text(
                          'Unlock Latyr Pro',
                          style: LTypography.roundedTitle2.copyWith(
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: LSpacing.xs),
                        Text(
                          'Supercharge your second brain with unlimited video extractions and cloud sync.',
                          textAlign: TextAlign.center,
                          style: LTypography.footnote.copyWith(
                            color: secondaryLabelColor,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: LSpacing.lg),
                        CupertinoButton.filled(
                          onPressed: () => PaywallModal.show(context, used: completedCount, limit: totalLimit),
                          child: const Text('Upgrade for \$4.99/mo'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: LSpacing.xl),

                  // ── Quota & Usage Section ───────────────────────────────────
                  CupertinoListSection.insetGrouped(
                    header: Text(
                      'MONTHLY USAGE',
                      style: LTypography.roundedEyebrow.copyWith(color: secondaryLabelColor),
                    ),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.chart_bar_fill, color: LColors.brandAmber),
                        title: Text('Captures Used', style: LTypography.body.copyWith(color: labelColor)),
                        trailing: Text(
                          '$completedCount / $totalLimit',
                          style: LTypography.subhead.rounded.copyWith(
                            color: secondaryLabelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: LSpacing.base, vertical: LSpacing.sm),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(color: LColors.brandAmber),
                            ),
                          ),
                        ),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.calendar, color: LColors.info),
                        title: Text('Billing Cycle', style: LTypography.body.copyWith(color: labelColor)),
                        additionalInfo: Text(
                          'Resets in 7 days',
                          style: LTypography.subhead.copyWith(color: secondaryLabelColor),
                        ),
                      ),
                    ],
                  ),

                  // ── Pro Features Section ────────────────────────────────────
                  CupertinoListSection.insetGrouped(
                    header: Text(
                      'PRO FEATURES INCLUDED',
                      style: LTypography.roundedEyebrow.copyWith(color: secondaryLabelColor),
                    ),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.checkmark_seal_fill, color: LColors.success),
                        title: Text('Unlimited Video Extractions', style: LTypography.body.copyWith(color: labelColor)),
                        subtitle: Text('Instagram Reels, TikToks & YouTube Shorts', style: LTypography.caption1.copyWith(color: secondaryLabelColor)),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.checkmark_seal_fill, color: LColors.success),
                        title: Text('Deep Entity Recognition', style: LTypography.body.copyWith(color: labelColor)),
                        subtitle: Text('Movies, places, recipes & code extracted automatically', style: LTypography.caption1.copyWith(color: secondaryLabelColor)),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.checkmark_seal_fill, color: LColors.success),
                        title: Text('Cross-Platform Sync', style: LTypography.body.copyWith(color: labelColor)),
                        subtitle: Text('Access your library across all devices', style: LTypography.caption1.copyWith(color: secondaryLabelColor)),
                      ),
                    ],
                  ),

                  // ── App Settings & Info Section ─────────────────────────────
                  CupertinoListSection.insetGrouped(
                    header: Text(
                      'ABOUT',
                      style: LTypography.roundedEyebrow.copyWith(color: secondaryLabelColor),
                    ),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.info_circle_fill, color: CupertinoColors.systemGrey),
                        title: Text('Version', style: LTypography.body.copyWith(color: labelColor)),
                        additionalInfo: Text('1.0.0 (Apple HIG)', style: LTypography.subhead.copyWith(color: secondaryLabelColor)),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.lock_shield_fill, color: CupertinoColors.systemGrey),
                        title: Text('Privacy Policy', style: LTypography.body.copyWith(color: labelColor)),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: LSpacing.xl3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
