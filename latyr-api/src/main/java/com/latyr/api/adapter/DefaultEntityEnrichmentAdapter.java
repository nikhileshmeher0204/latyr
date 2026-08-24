package com.latyr.api.adapter;

import com.latyr.api.domain.enums.EntityType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Zero-External-Dependency Entity Enrichment Provider.
 * All rich entity understanding (metadata, ratings, release years, languages, CTAs)
 * is extracted directly in one shot by Vertex AI Gemini multimodal inference.
 */
@Component
public class DefaultEntityEnrichmentAdapter implements EntityEnrichmentProvider {

    private static final Logger log = LoggerFactory.getLogger(DefaultEntityEnrichmentAdapter.class);
    private static final String DEFAULT_MOVIE_POSTER = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&q=80";

    @Override
    public List<AIProvider.AIEntity> enrichEntities(List<AIProvider.AIEntity> entities) {
        if (entities == null || entities.isEmpty()) {
            return Collections.emptyList();
        }

        List<AIProvider.AIEntity> enriched = new ArrayList<>();
        for (AIProvider.AIEntity entity : entities) {
            try {
                if (entity.entityType() == EntityType.TV_SHOW || entity.entityType() == EntityType.MOVIE) {
                    enriched.add(normalizeEntertainmentEntity(entity));
                } else if (entity.entityType() == EntityType.GITHUB_REPO) {
                    enriched.add(normalizeGithubEntity(entity));
                } else {
                    enriched.add(entity);
                }
            } catch (Exception e) {
                log.warn("Entity normalization error for '{}': {}. Passing through original.", entity.title(), e.getMessage());
                enriched.add(entity);
            }
        }
        return enriched;
    }

    private AIProvider.AIEntity normalizeEntertainmentEntity(AIProvider.AIEntity entity) {
        Map<String, Object> metadata = new HashMap<>(entity.metadata() != null ? entity.metadata() : Map.of());

        // Ensure a clean poster URL exists if not already extracted by Vertex AI
        if (!metadata.containsKey("poster_url") || metadata.get("poster_url") == null) {
            metadata.put("poster_url", DEFAULT_MOVIE_POSTER);
        }

        return new AIProvider.AIEntity(
                entity.entityType(),
                entity.title(),
                entity.description(),
                entity.externalUrl(),
                entity.actionCta(),
                metadata
        );
    }

    private AIProvider.AIEntity normalizeGithubEntity(AIProvider.AIEntity entity) {
        Map<String, Object> metadata = new HashMap<>(entity.metadata() != null ? entity.metadata() : Map.of());

        String url = entity.externalUrl();
        if (url == null || url.trim().isEmpty()) {
            String title = entity.title().trim();
            if (title.contains("/") && !title.contains(" ")) {
                url = "https://github.com/" + title;
            }
        }

        return new AIProvider.AIEntity(
                entity.entityType(),
                entity.title(),
                entity.description(),
                url,
                entity.actionCta(),
                metadata
        );
    }
}
