package com.latyr.api.worker;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.EntityEnrichmentProvider;
import com.latyr.api.domain.model.Capture;
import com.latyr.api.domain.model.ExtractedEntity;
import com.latyr.api.dto.ExtractedEntityResponse;
import com.latyr.api.mapper.CaptureMapper;
import com.latyr.api.mapper.ExtractedEntityMapper;
import com.latyr.api.service.SseNotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executor;

/**
 * Background outbox processor draining un-enriched entities.
 * Uses PostgreSQL FOR UPDATE SKIP LOCKED to guarantee idempotent, non-blocking execution across instances.
 */
@Component
public class EntityEnrichmentRetryWorker {

    private static final Logger log = LoggerFactory.getLogger(EntityEnrichmentRetryWorker.class);

    private final ExtractedEntityMapper entityMapper;
    private final EntityEnrichmentProvider entityEnricher;
    private final CaptureMapper captureMapper;
    private final SseNotificationService sseNotificationService;
    private final Executor virtualThreadExecutor;

    public EntityEnrichmentRetryWorker(
            ExtractedEntityMapper entityMapper,
            EntityEnrichmentProvider entityEnricher,
            CaptureMapper captureMapper,
            SseNotificationService sseNotificationService,
            @Qualifier("virtualThreadExecutor") Executor virtualThreadExecutor) {
        this.entityMapper = entityMapper;
        this.entityEnricher = entityEnricher;
        this.captureMapper = captureMapper;
        this.sseNotificationService = sseNotificationService;
        this.virtualThreadExecutor = virtualThreadExecutor;
    }

    @Scheduled(fixedDelay = 60000) // Runs every 60 seconds
    public void drainEnrichmentQueue() {
        try {
            List<ExtractedEntity> pendingEntities = entityMapper.fetchPendingForEnrichment(20);
            if (pendingEntities.isEmpty()) return;

            log.info("Draining {} pending entities for enrichment...", pendingEntities.size());

            for (ExtractedEntity entity : pendingEntities) {
                virtualThreadExecutor.execute(() -> processSinglePendingEntity(entity));
            }
        } catch (Exception e) {
            log.warn("Error during entity enrichment queue drain: {}", e.getMessage());
        }
    }

    private void processSinglePendingEntity(ExtractedEntity entity) {
        try {
            AIProvider.AIEntity raw = new AIProvider.AIEntity(
                    entity.getEntityType(),
                    entity.getTitle(),
                    entity.getDescription(),
                    entity.getExternalUrl(),
                    entity.getActionCta(),
                    entity.getMetadata()
            );

            List<AIProvider.AIEntity> enrichedList = entityEnricher.enrichEntities(List.of(raw));
            if (!enrichedList.isEmpty()) {
                AIProvider.AIEntity enriched = enrichedList.get(0);

                entity.setTitle(enriched.title());
                entity.setExternalUrl(enriched.externalUrl());
                entity.setActionCta(enriched.actionCta());
                entity.setMetadata(enriched.metadata());
                entity.setEnrichmentStatus("ENRICHED");
                entity.setEnrichmentError(null);
                entityMapper.update(entity);

                log.info("Successfully background-enriched entity '{}' ({})", entity.getTitle(), entity.getId());

                // Broadcast SSE event to active foreground mobile sessions
                if (sseNotificationService != null) {
                    captureMapper.findById(entity.getCaptureId()).ifPresent(capture -> {
                        sseNotificationService.emitCaptureEvent(
                                capture.getUserId(),
                                "ENTITY_ENRICHED",
                                Map.of(
                                        "capture_id", entity.getCaptureId(),
                                        "entity", ExtractedEntityResponse.fromModel(entity)
                                )
                        );
                    });
                }
            }
        } catch (Exception e) {
            int nextRetry = entity.getRetryCount() + 1;
            entity.setRetryCount(nextRetry);
            entity.setEnrichmentError(e.getMessage());

            if (nextRetry >= 5) {
                entity.setEnrichmentStatus("NOT_FOUND");
                log.warn("Entity '{}' ({}) reached max retries. Marking NOT_FOUND.", entity.getTitle(), entity.getId());
            } else {
                long backoffSeconds = (long) Math.pow(2, nextRetry) * 60; // 2m, 4m, 8m, 16m
                entity.setNextRetryAt(Instant.now().plusSeconds(backoffSeconds));
                log.info("Entity '{}' enrichment failed (attempt {}/5). Scheduled retry in {}s.", entity.getTitle(), nextRetry, backoffSeconds);
            }
            entityMapper.update(entity);
        }
    }
}
