package com.latyr.api.domain.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "capture_collections")
public class CaptureCollection {

    @EmbeddedId
    private CaptureCollectionId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("captureId")
    @JoinColumn(name = "capture_id")
    private Capture capture;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("userCollectionId")
    @JoinColumn(name = "user_collection_id")
    private UserCollection userCollection;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public CaptureCollection() {}

    public CaptureCollection(Capture capture, UserCollection userCollection) {
        this.capture = capture;
        this.userCollection = userCollection;
        this.id = new CaptureCollectionId(capture.getId(), userCollection.getId());
    }

    // Getters and Setters
    public CaptureCollectionId getId() { return id; }
    public void setId(CaptureCollectionId id) { this.id = id; }

    public Capture getCapture() { return capture; }
    public void setCapture(Capture capture) { this.capture = capture; }

    public UserCollection getUserCollection() { return userCollection; }
    public void setUserCollection(UserCollection userCollection) { this.userCollection = userCollection; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
