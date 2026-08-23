package com.latyr.latyr_api.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class CaptureCollectionId implements Serializable {

    @Column(name = "capture_id")
    private UUID captureId;

    @Column(name = "user_collection_id")
    private UUID userCollectionId;

    public CaptureCollectionId() {}

    public CaptureCollectionId(UUID captureId, UUID userCollectionId) {
        this.captureId = captureId;
        this.userCollectionId = userCollectionId;
    }

    public UUID getCaptureId() { return captureId; }
    public void setCaptureId(UUID captureId) { this.captureId = captureId; }

    public UUID getUserCollectionId() { return userCollectionId; }
    public void setUserCollectionId(UUID userCollectionId) { this.userCollectionId = userCollectionId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        CaptureCollectionId that = (CaptureCollectionId) o;
        return Objects.equals(captureId, that.captureId) && Objects.equals(userCollectionId, that.userCollectionId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(captureId, userCollectionId);
    }
}
