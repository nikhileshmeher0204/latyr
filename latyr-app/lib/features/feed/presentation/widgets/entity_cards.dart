import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EntityCardRouter extends StatelessWidget {
  final ExtractedEntityModel entity;

  const EntityCardRouter({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    switch (entity.entityType.toUpperCase()) {
      case 'MOVIE':
      case 'TV_SHOW':
        return _MovieShowCard(entity: entity);
      case 'GITHUB_REPO':
        return _GitHubRepoCard(entity: entity);
      case 'QUOTE':
        return _QuoteCard(entity: entity);
      default:
        return _GenericCard(entity: entity);
    }
  }
}

// ─── Movie / Show ────────────────────────────────────────────────────────────

class _MovieShowCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _MovieShowCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final posterUrl = entity.metadata['poster_url']?.toString();
    final rating = entity.metadata['rating']?.toString();
    final releaseYear = entity.metadata['release_year']?.toString();
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEEEC);
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return Container(
      margin: const EdgeInsets.only(top: LSpacing.sm),
      padding: const EdgeInsets.all(LSpacing.md - 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: LSpacing.brMD,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (posterUrl != null)
            ClipRRect(
              borderRadius: LSpacing.brSM,
              child: Image.network(
                posterUrl,
                width: 56,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 56,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFD1D1D6),
                    borderRadius: LSpacing.brSM,
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.film,
                      color: Color(0xFF8E8E93),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(width: posterUrl != null ? LSpacing.md : 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entity.title,
                        style: LTypography.footnoteSemibold.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: LSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LSpacing.xs + 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LColors.warning.withValues(alpha: 0.16),
                          borderRadius: LSpacing.brXS,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.star_fill,
                              size: 11,
                              color: LColors.warning,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: LTypography.caption2Bold.copyWith(
                                color: LColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (releaseYear != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    releaseYear,
                    style: LTypography.caption2.copyWith(color: secondaryColor),
                  ),
                ],
                if (entity.description != null &&
                    entity.description!.isNotEmpty) ...[
                  const SizedBox(height: LSpacing.xs),
                  Text(
                    entity.description!,
                    style: LTypography.caption1.copyWith(color: secondaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: LSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CtaButton(
                    ctaText: 'WATCH',
                    url: entity.externalUrl,
                    icon: CupertinoIcons.play_fill,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GitHub Repo ──────────────────────────────────────────────────────────────

class _GitHubRepoCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _GitHubRepoCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final stars = entity.metadata['stars']?.toString();
    final language = entity.metadata['language']?.toString();
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEEEC);
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return Container(
      margin: const EdgeInsets.only(top: LSpacing.sm),
      padding: const EdgeInsets.all(LSpacing.md - 2),
      decoration: BoxDecoration(color: bg, borderRadius: LSpacing.brMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.command, size: 16, color: LColors.royalIndigo),
              const SizedBox(width: LSpacing.sm),
              Expanded(
                child: Text(
                  entity.title,
                  style: LTypography.footnoteSemibold.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (stars != null) ...[
                const Icon(
                  CupertinoIcons.star,
                  size: 12,
                  color: Color(0xFF8E8E93),
                ),
                const SizedBox(width: 2),
                Text(stars, style: LTypography.caption2.copyWith(color: secondaryColor)),
              ],
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: LSpacing.xs),
            Text(
              entity.description!,
              style: LTypography.caption1.copyWith(color: secondaryColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: LSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (language != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFD1D1D6),
                    borderRadius: LSpacing.brXS,
                  ),
                  child: Text(
                    language,
                    style: LTypography.caption2.copyWith(color: secondaryColor),
                  ),
                )
              else
                const SizedBox.shrink(),
              _CtaButton(
                ctaText: 'GITHUB',
                url: entity.externalUrl,
                icon: CupertinoIcons.arrow_up_right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quote ────────────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _QuoteCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return Container(
      margin: const EdgeInsets.only(top: LSpacing.sm),
      padding: const EdgeInsets.all(LSpacing.md - 2),
      decoration: BoxDecoration(
        color: LColors.brandAmber.withValues(alpha: isDark ? 0.1 : 0.07),
        borderRadius: LSpacing.brMD,
        border: Border.all(
          color: LColors.brandAmber.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(CupertinoIcons.text_quote, color: LColors.brandAmberLight, size: 18),
              const SizedBox(width: LSpacing.sm),
              Expanded(
                child: Text(
                  '"${entity.title}"',
                  style: LTypography.footnote.copyWith(
                    color: labelColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: LSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                '— ${entity.description!}',
                style: LTypography.caption2.copyWith(color: secondaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Generic ─────────────────────────────────────────────────────────────────

class _GenericCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _GenericCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEEEC);
    final labelColor = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF121316);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A);

    return Container(
      margin: const EdgeInsets.only(top: LSpacing.sm),
      padding: const EdgeInsets.all(LSpacing.md - 2),
      decoration: BoxDecoration(color: bg, borderRadius: LSpacing.brMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForType(entity.entityType),
                size: 15,
                color: LColors.sageEmerald,
              ),
              const SizedBox(width: LSpacing.sm),
              Expanded(
                child: Text(
                  entity.title,
                  style: LTypography.footnoteSemibold.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entity.externalUrl != null)
                _CtaButton(
                  ctaText: entity.actionCta,
                  url: entity.externalUrl,
                  icon: CupertinoIcons.arrow_up_right,
                ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: LSpacing.xs),
            Text(
              entity.description!,
              style: LTypography.caption1.copyWith(color: secondaryColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'BOOK':
        return CupertinoIcons.book;
      case 'RECIPE':
        return CupertinoIcons.flame;
      case 'PLACE':
        return CupertinoIcons.map_pin;
      case 'TOOL':
        return CupertinoIcons.wrench;
      default:
        return CupertinoIcons.lightbulb;
    }
  }
}

// ─── CTA Button (no ElevatedButton) ──────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final String ctaText;
  final String? url;
  final IconData icon;

  const _CtaButton({
    required this.ctaText,
    required this.url,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (url != null && url!.isNotEmpty) {
          final uri = Uri.tryParse(url!);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LSpacing.sm + 2,
          vertical: LSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: LColors.brandAmber,
          borderRadius: LSpacing.brXS,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: LColors.staticWhite),
            const SizedBox(width: LSpacing.xs),
            Text(
              ctaText,
              style: LTypography.caption2Bold.copyWith(
                color: LColors.staticWhite,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
