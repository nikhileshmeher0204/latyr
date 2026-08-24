package com.latyr.api.domain.model;

import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class ExtractedEntity {

    private UUID id;
    private UUID captureId;
    private EntityType entityType;
    private String title;
    private String description;
    private String externalUrl;
    private ActionCTA actionCta;
    private Map<String, Object> metadata = new HashMap<>();
    private Instant createdAt = Instant.now();

    public ExtractedEntity() {}

    public ExtractedEntity(UUID captureId, EntityType entityType, String title) {
        this.captureId = captureId;
        this.entityType = entityType;
        this.title = title;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getCaptureId() { return captureId; }
    public void setCaptureId(UUID captureId) { this.captureId = captureId; }

    public EntityType getEntityType() { return entityType; }
    public void setEntityType(EntityType entityType) { this.entityType = entityType; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getExternalUrl() { return externalUrl; }
    public void setExternalUrl(String externalUrl) { this.externalUrl = externalUrl; }

    public ActionCTA getActionCta() { return actionCta; }
    public void setActionCta(ActionCTA actionCta) { this.actionCta = actionCta; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
