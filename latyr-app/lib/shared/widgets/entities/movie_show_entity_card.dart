import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';
import 'package:latyr_app/shared/widgets/pill_button.dart';
import 'package:url_launcher/url_launcher.dart';

class MovieShowEntityCard extends StatelessWidget {
  final String title;
  final String? description;
  final double? rating;
  final String? releaseYearOrSeasons;
  final String? posterUrl;
  final String? externalUrl;
  final String platform;
  final VoidCallback? onTap;

  const MovieShowEntityCard({
    super.key,
    required this.title,
    this.description,
    this.rating,
    this.releaseYearOrSeasons,
    this.posterUrl,
    this.externalUrl,
    this.platform = 'Netflix',
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
    return GlassCard.obsidian(
      borderRadius: LSpacing.radiusLG + 2,
      padding: const EdgeInsets.all(LSpacing.md),
      onTap: onTap ?? _handleAction,
      child: Row(
        children: [
          // Poster Thumbnail / Fallback
          ClipRRect(
            borderRadius: LSpacing.brSM,
            child: Container(
              width: 50,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LColors.terracottaDark, Color(0xFF32080D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: LColors.staticWhite12),
              ),
              child: posterUrl != null && posterUrl!.isNotEmpty
                  ? Image.network(
                      posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackPoster(),
                    )
                  : _buildFallbackPoster(),
            ),
          ),
          const SizedBox(width: LSpacing.md),

          // Title & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: LTypography.subheadlineMedium.copyWith(
                    color: LColors.staticWhite,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: LSpacing.xs),
                Row(
                  children: [
                    if (rating != null) ...[
                      Text(
                        '${rating!.toStringAsFixed(1)} ★',
                        style: LTypography.caption1Bold.copyWith(
                          color: LColors.brandAmberLight,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: LTypography.caption1.copyWith(color: LColors.staticWhite40),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        releaseYearOrSeasons ?? platform,
                        style: LTypography.caption1.copyWith(color: LColors.staticWhite70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Watch CTA
          PillButton(
            text: 'Watch',
            height: 32,
            variant: PillButtonVariant.solidAmber,
            onPressed: _handleAction,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPoster() {
    return Center(
      child: Icon(
        CupertinoIcons.play_fill,
        size: 22,
        color: LColors.staticWhite70,
      ),
    );
  }
}
