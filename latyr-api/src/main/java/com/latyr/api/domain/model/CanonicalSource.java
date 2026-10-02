package com.latyr.api.domain.model;

import com.latyr.api.domain.enums.SourceType;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class CanonicalSource {

    private UUID id;
    private String canonicalUrlHash;
    private SourceType sourceType;
    private String originalUrl;
    private String thumbnailUrl;
    private Map<String, Object> rawMetadata = new HashMap<>();
    private Map<String, Object> aiAnalysisCache = new HashMap<>();
    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    public CanonicalSource() {}

    public CanonicalSource(String canonicalUrlHash, SourceType sourceType, String originalUrl) {
        this.canonicalUrlHash = canonicalUrlHash;
        this.sourceType = sourceType;
        this.originalUrl = originalUrl;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getCanonicalUrlHash() { return canonicalUrlHash; }
    public void setCanonicalUrlHash(String canonicalUrlHash) { this.canonicalUrlHash = canonicalUrlHash; }

    public SourceType getSourceType() { return sourceType; }
    public void setSourceType(SourceType sourceType) { this.sourceType = sourceType; }

    public String getOriginalUrl() { return originalUrl; }
    public void setOriginalUrl(String originalUrl) { this.originalUrl = originalUrl; }

    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }

    public Map<String, Object> getRawMetadata() { return rawMetadata; }
    public void setRawMetadata(Map<String, Object> rawMetadata) { this.rawMetadata = rawMetadata; }

    public Map<String, Object> getAiAnalysisCache() { return aiAnalysisCache; }
    public void setAiAnalysisCache(Map<String, Object> aiAnalysisCache) { this.aiAnalysisCache = aiAnalysisCache; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
