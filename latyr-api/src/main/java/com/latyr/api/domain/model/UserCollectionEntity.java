package com.latyr.api.domain.model;

import java.time.Instant;
import java.util.UUID;

public class UserCollectionEntity {

    private UUID userCollectionId;
    private UUID entityId;
    private int itemOrder = 0;
    private Instant addedAt = Instant.now();

    public UserCollectionEntity() {}

    public UserCollectionEntity(UUID userCollectionId, UUID entityId, int itemOrder) {
        this.userCollectionId = userCollectionId;
        this.entityId = entityId;
        this.itemOrder = itemOrder;
    }

    public UUID getUserCollectionId() { return userCollectionId; }
    public void setUserCollectionId(UUID userCollectionId) { this.userCollectionId = userCollectionId; }

    public UUID getEntityId() { return entityId; }
    public void setEntityId(UUID entityId) { this.entityId = entityId; }

    public int getItemOrder() { return itemOrder; }
    public void setItemOrder(int itemOrder) { this.itemOrder = itemOrder; }

    public Instant getAddedAt() { return addedAt; }
    public void setAddedAt(Instant addedAt) { this.addedAt = addedAt; }
}
