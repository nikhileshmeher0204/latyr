package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.EntityEnrichmentProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;

/**
 * Composite Entity Enrichment Orchestrator.
 * Dispatches raw entities to domain-specific enrichers concurrently on Java 21 Virtual Threads.
 */
@Service
@Primary
public class CompositeEntityEnricher implements EntityEnrichmentProvider {

    private static final Logger log = LoggerFactory.getLogger(CompositeEntityEnricher.class);

    private final List<EntityEnricher> enrichers;
    private final Executor executor;

    public CompositeEntityEnricher(
            List<EntityEnricher> enrichers,
            @Qualifier("virtualThreadExecutor") Executor executor) {
        this.enrichers = enrichers.stream()
                .sorted(Comparator.comparingInt(EntityEnricher::getOrder))
                .toList();
        this.executor = executor;
        log.info("Initialized CompositeEntityEnricher with {} enrichers: {}",
                this.enrichers.size(),
                this.enrichers.stream().map(e -> e.getClass().getSimpleName()).toList());
    }

    @Override
    public List<AIProvider.AIEntity> enrichEntities(List<AIProvider.AIEntity> entities) {
        if (entities == null || entities.isEmpty()) {
            return Collections.emptyList();
        }

        // Concurrently enrich all entities using Project Loom Virtual Threads
        List<CompletableFuture<AIProvider.AIEntity>> futures = entities.stream()
                .map(entity -> CompletableFuture.supplyAsync(
                        () -> enrichSingleEntity(entity),
                        executor
                ))
                .toList();

        return futures.stream()
                .map(CompletableFuture::join)
                .toList();
    }

    private AIProvider.AIEntity enrichSingleEntity(AIProvider.AIEntity rawEntity) {
        if (rawEntity == null) return null;

        for (EntityEnricher enricher : enrichers) {
            if (enricher.supports(rawEntity.entityType())) {
                try {
                    return enricher.enrich(rawEntity);
                } catch (Exception e) {
                    log.warn("Enricher {} failed for '{}': {}. Falling back to raw entity.",
                            enricher.getClass().getSimpleName(), rawEntity.title(), e.getMessage());
                    return rawEntity;
                }
            }
        }
        return rawEntity;
    }
}
