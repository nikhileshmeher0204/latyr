import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';
import 'package:latyr_app/shared/widgets/pill_button.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubRepoEntityCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? language;
  final int? stars;
  final String? externalUrl;
  final VoidCallback? onTap;

  const GitHubRepoEntityCard({
    super.key,
    required this.title,
    this.description,
    this.language,
    this.stars,
    this.externalUrl,
    this.onTap,
  });

  Future<void> _handleAction() async {
    if (externalUrl != null && externalUrl!.isNotEmpty) {
      final uri = Uri.tryParse(externalUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final iconBg = isDark ? const Color(0x226366F1) : const Color(0xFFEFF1FF);

    return GlassCard(
      borderRadius: LSpacing.radiusLG + 2,
      padding: const EdgeInsets.all(LSpacing.md),
      onTap: onTap ?? _handleAction,
      child: Row(
        children: [
          // Repo icon badge
          Container(
            width: LSpacing.minTapTarget,
            height: LSpacing.minTapTarget,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: LSpacing.brSM,
              border: Border.all(
                color: LColors.royalIndigo.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.command,
                size: 20,
                color: LColors.royalIndigo,
              ),
            ),
          ),
          const SizedBox(width: LSpacing.md),

          // Repo Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: LTypography.footnoteSemibold.copyWith(
                    color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: LSpacing.xs - 1),
                Row(
                  children: [
                    if (language != null) ...[
                      Text(
                        language!,
                        style: LTypography.caption2Bold.copyWith(
                          color: LColors.royalIndigo,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: LTypography.caption2.copyWith(
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A),
                        ),
                      ),
                    ],
                    Text(
                      stars != null ? '★ $stars' : 'GitHub Repo',
                      style: LTypography.caption2.copyWith(
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Open Action
          PillButton(
            text: 'Explore',
            height: 32,
            variant: PillButtonVariant.glass,
            onPressed: _handleAction,
          ),
        ],
      ),
    );
  }
}
