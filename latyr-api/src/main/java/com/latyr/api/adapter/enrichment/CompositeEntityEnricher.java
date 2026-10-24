package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.EntityEnrichmentProvider;
import com.latyr.api.exception.ProviderOperationException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.concurrent.Semaphore;
import static com.latyr.api.exception.ProviderOperationException.Outcome.*;

/** Bounds provider work across jobs without spawning an unbounded entity fan-out. */
@Service
@Primary
public class CompositeEntityEnricher implements EntityEnrichmentProvider {
    private final List<EntityEnricher> enrichers;
    private final Semaphore capacity;

    public CompositeEntityEnricher(List<EntityEnricher> enrichers,
            @Value("${latyr.enrichment.max-concurrency:4}") int maxConcurrency) {
        if (maxConcurrency < 1) throw new IllegalArgumentException("Enrichment concurrency must be positive");
        this.enrichers = enrichers.stream().sorted(Comparator.comparingInt(EntityEnricher::getOrder)).toList();
        this.capacity = new Semaphore(maxConcurrency);
    }

    @Override
    public List<AIProvider.AIEntity> enrichEntities(List<AIProvider.AIEntity> entities) {
        if (entities == null || entities.isEmpty()) return List.of();
        List<AIProvider.AIEntity> result = new ArrayList<>();
        for (AIProvider.AIEntity entity : entities) result.add(enrichSingleEntity(entity));
        return List.copyOf(result);
    }

    private AIProvider.AIEntity enrichSingleEntity(AIProvider.AIEntity entity) {
        if (entity == null) throw new ProviderOperationException("INVALID_ENRICHMENT_ENTITY", PERMANENT);
        for (EntityEnricher enricher : enrichers) {
            if (!enricher.supports(entity)) continue;
            try {
                capacity.acquire();
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
                throw new ProviderOperationException("ENRICHMENT_INTERRUPTED", RETRYABLE);
            }
            try {
                AIProvider.AIEntity enriched = enricher.enrich(entity);
                if (enriched == null) throw new ProviderOperationException("ENRICHMENT_INVALID_RESPONSE", RETRYABLE);
                return enriched;
            } catch (ProviderOperationException failure) {
                throw failure;
            } catch (Exception failure) {
                throw new ProviderOperationException("ENRICHMENT_UNAVAILABLE", RETRYABLE);
            } finally {
                capacity.release();
            }
        }
        return entity;
    }
}
