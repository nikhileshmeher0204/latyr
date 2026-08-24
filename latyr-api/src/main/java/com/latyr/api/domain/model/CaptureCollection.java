package com.latyr.api.domain.model;

import java.time.Instant;
import java.util.UUID;

public class CaptureCollection {

    private UUID captureId;
    private UUID userCollectionId;
    private Instant addedAt = Instant.now();

    public CaptureCollection() {}

    public CaptureCollection(UUID captureId, UUID userCollectionId) {
        this.captureId = captureId;
        this.userCollectionId = userCollectionId;
    }

    public UUID getCaptureId() { return captureId; }
    public void setCaptureId(UUID captureId) { this.captureId = captureId; }

    public UUID getUserCollectionId() { return userCollectionId; }
    public void setUserCollectionId(UUID userCollectionId) { this.userCollectionId = userCollectionId; }

    public Instant getAddedAt() { return addedAt; }
    public void setAddedAt(Instant addedAt) { this.addedAt = addedAt; }
}
