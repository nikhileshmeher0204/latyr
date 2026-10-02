import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/shared/widgets/apple_tv_badge.dart';
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

// ─── Movie / Show Card ───────────────────────────────────────────────────────

class _MovieShowCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _MovieShowCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final posterUrl = entity.metadata['poster_url']?.toString();
    final rating = entity.metadata['rating']?.toString();
    final releaseYear = entity.metadata['release_year']?.toString();

    return _AppleTvCardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (posterUrl != null && posterUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                posterUrl,
                width: 54,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _buildPlaceholderPoster(),
              ),
            )
          else
            _buildPlaceholderPoster(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 6),
                      AppleTvBadge(label: rating, emoji: '★'),
                    ],
                  ],
                ),
                if (releaseYear != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    releaseYear,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (entity.description != null && entity.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entity.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _AppleTvCtaButton(
                    ctaText: 'WATCH',
                    url: entity.externalUrl,
                    icon: CupertinoIcons.play_arrow_solid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 54,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
      ),
      child: const Center(
        child: Icon(
          CupertinoIcons.film,
          color: Color(0xFFBF5AF2),
          size: 24,
        ),
      ),
    );
  }
}

// ─── GitHub Repo Card ─────────────────────────────────────────────────────────

class _GitHubRepoCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _GitHubRepoCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final stars = entity.metadata['stars']?.toString();
    final language = entity.metadata['language']?.toString();

    return _AppleTvCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconSquare(
                icon: CupertinoIcons.chevron_left_slash_chevron_right,
                iconColor: const Color(0xFF64D2FF),
                bgColor: const Color(0xFF64D2FF).withValues(alpha: 0.15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const AppleTvBadge(label: 'REPO', fontSize: 9),
                        if (stars != null) ...[
                          const SizedBox(width: 5),
                          AppleTvBadge(label: stars, emoji: '★', fontSize: 9),
                        ],
                        if (language != null) ...[
                          const SizedBox(width: 5),
                          AppleTvBadge(label: language.toUpperCase(), fontSize: 9),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (entity.externalUrl != null)
                _AppleTvCtaButton(
                  ctaText: 'GITHUB',
                  url: entity.externalUrl,
                  icon: CupertinoIcons.arrow_up_right,
                ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entity.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Quote Card ──────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _QuoteCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    return _AppleTvCardContainer(
      borderColor: LColors.brandAmber.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconSquare(
                icon: CupertinoIcons.quote_bubble_fill,
                iconColor: LColors.brandAmber,
                bgColor: LColors.brandAmber.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '“${entity.title}”',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(
                '— ${entity.description!}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Generic Card (Tools, Places, Books, Food, etc.) ─────────────────────────

class _GenericCard extends StatelessWidget {
  final ExtractedEntityModel entity;
  const _GenericCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final typeInfo = _resolveTypeInfo(entity.entityType);

    return _AppleTvCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconSquare(
                icon: typeInfo.icon,
                iconColor: typeInfo.color,
                bgColor: typeInfo.color.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AppleTvBadge(
                      label: entity.entityType.toUpperCase(),
                      fontSize: 9,
                    ),
                  ],
                ),
              ),
              if (entity.externalUrl != null && entity.externalUrl!.isNotEmpty)
                _AppleTvCtaButton(
                  ctaText: entity.actionCta,
                  url: entity.externalUrl,
                  icon: CupertinoIcons.arrow_up_right,
                ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entity.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  _TypeInfo _resolveTypeInfo(String type) {
    switch (type.toUpperCase()) {
      case 'BOOK':
        return _TypeInfo(CupertinoIcons.book_fill, const Color(0xFFFF9F0A));
      case 'RECIPE':
        return _TypeInfo(CupertinoIcons.flame_fill, const Color(0xFFFF453A));
      case 'PLACE':
        return _TypeInfo(CupertinoIcons.map_pin_ellipse, const Color(0xFF30D158));
      case 'TOOL':
        return _TypeInfo(CupertinoIcons.wrench_fill, const Color(0xFF64D2FF));
      default:
        return _TypeInfo(CupertinoIcons.sparkles, const Color(0xFFBF5AF2));
    }
  }
}

class _TypeInfo {
  final IconData icon;
  final Color color;
  _TypeInfo(this.icon, this.color);
}

// ─── Card Container (Apple TV Frosted Dark Surface) ───────────────────────────

class _AppleTvCardContainer extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _AppleTvCardContainer({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.1),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget _buildIconSquare({
  required IconData icon,
  required Color iconColor,
  required Color bgColor,
}) {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: iconColor.withValues(alpha: 0.3),
        width: 0.8,
      ),
    ),
    child: Center(
      child: Icon(icon, size: 18, color: iconColor),
    ),
  );
}

// ─── Apple TV Glass CTA Button ────────────────────────────────────────────────

class _AppleTvCtaButton extends StatelessWidget {
  final String ctaText;
  final String? url;
  final IconData icon;

  const _AppleTvCtaButton({
    required this.ctaText,
    required this.url,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () async {
        if (url != null && url!.isNotEmpty) {
          final uri = Uri.tryParse(url!);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctaText.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 10, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
