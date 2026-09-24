import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';

class PaywallModal extends StatelessWidget {
  final int usedCaptures;
  final int quotaLimit;

  const PaywallModal({
    super.key,
    this.usedCaptures = 12,
    this.quotaLimit = 30,
  });

  static void show(BuildContext context, {int used = 12, int limit = 30}) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => PaywallModal(usedCaptures: used, quotaLimit: limit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (usedCaptures / quotaLimit).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121316),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(
          top: BorderSide(color: Color(0x1AFFFFFF)),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LSpacing.xl,
        vertical: LSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag Handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: LSpacing.brPill,
                ),
              ),
            ),
            const SizedBox(height: LSpacing.xl),

            // ── Pro Badge ────────────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LSpacing.md,
                  vertical: LSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LColors.brandAmber, Color(0xFFC05621)],
                  ),
                  borderRadius: LSpacing.brPill,
                ),
                child: Text(
                  'LATYR PRO',
                  style: LTypography.caption2Bold.copyWith(
                    color: LColors.staticWhite,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: LSpacing.md),

            // ── Headline ─────────────────────────────────────────────────────
            Text(
              'Unlock Unlimited Knowledge',
              textAlign: TextAlign.center,
              style: LTypography.title2.copyWith(
                color: LColors.staticWhite,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: LSpacing.xs),
            Text(
              'Capture every Reel, recipe, and tool without monthly limits.',
              textAlign: TextAlign.center,
              style: LTypography.footnote.copyWith(
                color: const Color(0xFFAEAEB2),
                height: 1.4,
              ),
            ),
            const SizedBox(height: LSpacing.xl),

            // ── Quota Meter ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(LSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: LSpacing.brMD,
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Free Quota',
                        style: LTypography.caption1.copyWith(
                          color: const Color(0xFFAEAEB2),
                        ),
                      ),
                      Text(
                        '$usedCaptures / $quotaLimit captures',
                        style: LTypography.caption1Bold.copyWith(
                          color: LColors.staticWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LSpacing.md - 2),

                  // Custom iOS-style progress bar (no Material needed)
                  ClipRRect(
                    borderRadius: LSpacing.brXS,
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            color: const Color(0x1AFFFFFF),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [LColors.brandAmber, Color(0xFFC05621)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LSpacing.xl),

            // ── Perks ────────────────────────────────────────────────────────
            _buildPerk(
              CupertinoIcons.arrow_right_arrow_left,
              '1,000 Captures / Month',
              'Save unlimited Reels, Shorts & web links',
            ),
            _buildPerk(
              CupertinoIcons.bolt_fill,
              'Priority Gemini 2.5 Multimodal AI',
              'Instant audio transcription & OCR vision extraction',
            ),
            _buildPerk(
              CupertinoIcons.bell_fill,
              'Personalized Resurfacing',
              'Smart Friday watchlist & Sunday digests',
            ),
            _buildPerk(
              CupertinoIcons.arrow_down_circle_fill,
              'Full Offline SQLite Sync',
              'Instant capture from share sheet in <300ms',
            ),

            const SizedBox(height: LSpacing.xl),

            // ── CTA Button ───────────────────────────────────────────────────
            CupertinoButton(
              borderRadius: LSpacing.brMD,
              color: LColors.brandAmber,
              onPressed: () {
                Navigator.of(context).pop();
                _showUpgradeConfirmation(context);
              },
              child: Text(
                'Upgrade to Pro — \$4.99 / month',
                style: LTypography.buttonLabel.copyWith(
                  color: LColors.staticWhite,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: LSpacing.md),

            Center(
              child: Text(
                'Cancel anytime. Powered by RevenueCat.',
                style: LTypography.caption2.copyWith(
                  color: const Color(0xFFAEAEB2),
                ),
              ),
            ),
            const SizedBox(height: LSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildPerk(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(LSpacing.sm),
            decoration: BoxDecoration(
              color: LColors.brandAmber.withValues(alpha: 0.15),
              borderRadius: LSpacing.brXS,
            ),
            child: Icon(icon, size: 16, color: LColors.brandAmber),
          ),
          const SizedBox(width: LSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LTypography.footnoteSemibold.copyWith(
                    color: LColors.staticWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: LTypography.caption1.copyWith(
                    color: const Color(0xFFAEAEB2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Upgraded to PRO!',
          style: LTypography.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'RevenueCat Sandbox: Upgraded to Latyr PRO tier.',
          style: LTypography.footnote,
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
