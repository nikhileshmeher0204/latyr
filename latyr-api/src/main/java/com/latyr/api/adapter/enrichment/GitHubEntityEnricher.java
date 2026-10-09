package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.domain.enums.EntityType;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/**
 * Baseline GitHub Entity Enricher normalizing repository links.
 * Prepared for Phase 3 live stars and license enrichment.
 */
@Component
@Order(50)
public class GitHubEntityEnricher implements EntityEnricher {

    @Override
    public boolean supports(EntityType entityType) {
        return entityType == EntityType.GITHUB_REPO;
    }

    @Override
    public AIProvider.AIEntity enrich(AIProvider.AIEntity entity) {
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
