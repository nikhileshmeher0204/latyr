package com.latyr.api.dto;

import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.model.ExtractedEntity;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record ExtractedEntityResponse(
        UUID id,
        UUID captureId,
        EntityType entityType,
        String title,
        String description,
        String externalUrl,
        ActionCTA actionCta,
        Map<String, Object> metadata,
        String enrichmentStatus,
        Instant createdAt
) {
    public static ExtractedEntityResponse fromModel(ExtractedEntity entity) {
        return new ExtractedEntityResponse(
                entity.getId(),
                entity.getCaptureId(),
                entity.getEntityType(),
                entity.getTitle(),
                entity.getDescription(),
                entity.getExternalUrl(),
                entity.getActionCta(),
                entity.getMetadata(),
                entity.getEnrichmentStatus(),
                entity.getCreatedAt()
        );
    }
}
