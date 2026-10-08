import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/shared/widgets/glass_card.dart';

class Library1x2GridWidget extends StatelessWidget {
  final VoidCallback onMoviesTap;
  final VoidCallback onReposTap;
  final int moviesCount;
  final int reposCount;

  const Library1x2GridWidget({
    super.key,
    required this.onMoviesTap,
    required this.onReposTap,
    this.moviesCount = 24,
    this.reposCount = 11,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Row(
      children: [
        // Card 1: Movies & Shows
        Expanded(
          child: GlassCard(
            borderRadius: LSpacing.radiusLG + 2,
            padding: const EdgeInsets.all(LSpacing.md),
            onTap: onMoviesTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(
                  icon: CupertinoIcons.film_fill,
                  color: LColors.terracotta,
                  bgColor: isDark ? const Color(0x22D9534F) : const Color(0xFFFDF2F0),
                  isDark: isDark,
                ),
                const SizedBox(height: LSpacing.md),
                Text(
                  'Movies & Shows',
                  style: LTypography.footnoteSemibold.rounded.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316),
                    letterSpacing: -0.15,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '$moviesCount saved',
                  style: LTypography.caption2.rounded.copyWith(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: LSpacing.md),

        // Card 2: GitHub Repos
        Expanded(
          child: GlassCard(
            borderRadius: LSpacing.radiusLG + 2,
            padding: const EdgeInsets.all(LSpacing.md),
            onTap: onReposTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(
                  icon: CupertinoIcons.command,
                  color: LColors.royalIndigo,
                  bgColor: isDark ? const Color(0x226366F1) : const Color(0xFFEFF1FF),
                  isDark: isDark,
                ),
                const SizedBox(height: LSpacing.md),
                Text(
                  'GitHub Repos',
                  style: LTypography.footnoteSemibold.rounded.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316),
                    letterSpacing: -0.15,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '$reposCount saved',
                  style: LTypography.caption2.rounded.copyWith(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A),
                    fontWeight: FontWeight.w500,
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

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isDark;

  const _IconBadge({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: LSpacing.brSM,
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
