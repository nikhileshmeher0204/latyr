package com.latyr.api.domain.model;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class UserCollection {

    private UUID id;
    private UUID userId;
    private UUID collectionId;
    private String name;
    private String category;
    private String description;
    private String icon = "folder_fill";
    private String colorHex = "#28543A";
    private boolean isPinned = false;
    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    // Aggregated / transient fields for collection list previews
    private int itemCount = 0;
    private List<String> previewArtworkUrls = new ArrayList<>();

    public UserCollection() {}

    public UserCollection(UUID userId, String name, String category) {
        this.userId = userId;
        this.name = name;
        this.category = category;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getCollectionId() { return collectionId; }
    public void setCollectionId(UUID collectionId) { this.collectionId = collectionId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public String getColorHex() { return colorHex; }
    public void setColorHex(String colorHex) { this.colorHex = colorHex; }

    public boolean isPinned() { return isPinned; }
    public void setPinned(boolean pinned) { isPinned = pinned; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public int getItemCount() { return itemCount; }
    public void setItemCount(int itemCount) { this.itemCount = itemCount; }

    public List<String> getPreviewArtworkUrls() { return previewArtworkUrls; }
    public void setPreviewArtworkUrls(List<String> previewArtworkUrls) {
        this.previewArtworkUrls = previewArtworkUrls != null ? previewArtworkUrls : new ArrayList<>();
    }
}
