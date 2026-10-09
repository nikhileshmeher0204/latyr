package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.domain.enums.EntityType;

/**
 * Strategy SPI for domain-specific entity enrichment.
 * Implementations are discovered and executed by CompositeEntityEnricher.
 */
public interface EntityEnricher {

    /**
     * Determines whether this enricher supports the given entity type.
     */
    boolean supports(EntityType entityType);

    /**
     * Enriches the raw entity with domain-verified metadata (posters, ratings, URLs).
     */
    AIProvider.AIEntity enrich(AIProvider.AIEntity rawEntity);

    /**
     * Execution order / priority (lower = higher priority).
     */
    default int getOrder() {
        return 100;
    }
}
