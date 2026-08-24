import 'package:flutter/material.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
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
        return MovieShowEntityCard(entity: entity);
      case 'GITHUB_REPO':
        return GitHubRepoEntityCard(entity: entity);
      case 'QUOTE':
        return QuoteEntityCard(entity: entity);
      default:
        return GenericEntityCard(entity: entity);
    }
  }
}

class MovieShowEntityCard extends StatelessWidget {
  final ExtractedEntityModel entity;

  const MovieShowEntityCard({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    final posterUrl = entity.metadata['poster_url']?.toString();
    final rating = entity.metadata['rating']?.toString();
    final releaseYear = entity.metadata['release_year']?.toString();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (posterUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                posterUrl,
                width: 60,
                height: 85,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 85,
                  color: AppTheme.surface,
                  child: const Icon(Icons.movie, color: AppTheme.textMuted),
                ),
              ),
            ),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (releaseYear != null)
                  Text(
                    releaseYear,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                if (entity.description != null && entity.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entity.description!,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CtaButton(
                    ctaText: 'WATCH',
                    url: entity.externalUrl,
                    icon: Icons.play_arrow_rounded,
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

class GitHubRepoEntityCard extends StatelessWidget {
  final ExtractedEntityModel entity;

  const GitHubRepoEntityCard({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    final stars = entity.metadata['stars']?.toString();
    final language = entity.metadata['language']?.toString();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded, size: 18, color: AppTheme.primaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entity.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (stars != null)
                Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      stars,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entity.description!,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (language != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    language,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                )
              else
                const SizedBox.shrink(),
              _CtaButton(
                ctaText: 'OPEN GITHUB',
                url: entity.externalUrl,
                icon: Icons.open_in_new_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuoteEntityCard extends StatelessWidget {
  final ExtractedEntityModel entity;

  const QuoteEntityCard({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"${entity.title}"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 26),
              child: Text(
                '— ${entity.description!}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class GenericEntityCard extends StatelessWidget {
  final ExtractedEntityModel entity;

  const GenericEntityCard({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconForType(entity.entityType), size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entity.externalUrl != null)
                _CtaButton(
                  ctaText: entity.actionCta,
                  url: entity.externalUrl,
                  icon: Icons.launch_rounded,
                ),
            ],
          ),
          if (entity.description != null && entity.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entity.description!,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'BOOK': return Icons.menu_book_rounded;
      case 'RECIPE': return Icons.restaurant_rounded;
      case 'PLACE': return Icons.place_rounded;
      case 'TOOL': return Icons.build_rounded;
      default: return Icons.lightbulb_outline_rounded;
    }
  }
}

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
    return ElevatedButton.icon(
      onPressed: () async {
        if (url != null && url!.isNotEmpty) {
          final uri = Uri.tryParse(url!);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      icon: Icon(icon, size: 14),
      label: Text(
        ctaText,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
