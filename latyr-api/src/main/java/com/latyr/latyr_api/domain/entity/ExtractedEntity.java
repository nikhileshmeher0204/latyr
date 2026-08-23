package com.latyr.latyr_api.domain.entity;

import com.latyr.latyr_api.domain.enums.ActionCTA;
import com.latyr.latyr_api.domain.enums.EntityType;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "extracted_entities")
public class ExtractedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "capture_id", nullable = false)
    private Capture capture;

    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false, length = 32)
    private EntityType entityType;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "external_url", columnDefinition = "TEXT")
    private String externalUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "action_cta", nullable = false, length = 32)
    private ActionCTA actionCta;

    @Column(name = "metadata", nullable = false, columnDefinition = "jsonb")
    private String metadata = "{}";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void onPreUpdate() {
        this.updatedAt = Instant.now();
    }

    public ExtractedEntity() {}

    public ExtractedEntity(Capture capture, EntityType entityType, String title, ActionCTA actionCta) {
        this.capture = capture;
        this.entityType = entityType;
        this.title = title;
        this.actionCta = actionCta;
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Capture getCapture() { return capture; }
    public void setCapture(Capture capture) { this.capture = capture; }

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

    public String getMetadata() { return metadata; }
    public void setMetadata(String metadata) { this.metadata = metadata; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
