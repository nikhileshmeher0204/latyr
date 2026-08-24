package com.latyr.api.domain.entity;

import com.latyr.api.domain.enums.SourceType;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "canonical_sources")
public class CanonicalSource {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "canonical_url_hash", nullable = false, unique = true, length = 64)
    private String canonicalUrlHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 32)
    private SourceType sourceType;

    @Column(name = "original_url", nullable = false, columnDefinition = "TEXT")
    private String originalUrl;

    @Column(name = "raw_metadata", nullable = false, columnDefinition = "jsonb")
    private String rawMetadata = "{}";

    @Column(name = "ai_analysis_cache", columnDefinition = "jsonb")
    private String aiAnalysisCache;

    @Column(name = "scraping_duration_ms")
    private Integer scrapingDurationMs;

    @Column(name = "ai_inference_duration_ms")
    private Integer aiInferenceDurationMs;

    @Column(name = "total_processing_duration_ms")
    private Integer totalProcessingDurationMs;

    @Column(name = "first_processed_at", nullable = false, updatable = false)
    private Instant firstProcessedAt = Instant.now();

    @Column(name = "last_processed_at", nullable = false)
    private Instant lastProcessedAt = Instant.now();

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void onPreUpdate() {
        this.updatedAt = Instant.now();
    }

    public CanonicalSource() {}

    public CanonicalSource(String canonicalUrlHash, SourceType sourceType, String originalUrl) {
        this.canonicalUrlHash = canonicalUrlHash;
        this.sourceType = sourceType;
        this.originalUrl = originalUrl;
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getCanonicalUrlHash() { return canonicalUrlHash; }
    public void setCanonicalUrlHash(String canonicalUrlHash) { this.canonicalUrlHash = canonicalUrlHash; }

    public SourceType getSourceType() { return sourceType; }
    public void setSourceType(SourceType sourceType) { this.sourceType = sourceType; }

    public String getOriginalUrl() { return originalUrl; }
    public void setOriginalUrl(String originalUrl) { this.originalUrl = originalUrl; }

    public String getRawMetadata() { return rawMetadata; }
    public void setRawMetadata(String rawMetadata) { this.rawMetadata = rawMetadata; }

    public String getAiAnalysisCache() { return aiAnalysisCache; }
    public void setAiAnalysisCache(String aiAnalysisCache) { this.aiAnalysisCache = aiAnalysisCache; }

    public Integer getScrapingDurationMs() { return scrapingDurationMs; }
    public void setScrapingDurationMs(Integer scrapingDurationMs) { this.scrapingDurationMs = scrapingDurationMs; }

    public Integer getAiInferenceDurationMs() { return aiInferenceDurationMs; }
    public void setAiInferenceDurationMs(Integer aiInferenceDurationMs) { this.aiInferenceDurationMs = aiInferenceDurationMs; }

    public Integer getTotalProcessingDurationMs() { return totalProcessingDurationMs; }
    public void setTotalProcessingDurationMs(Integer totalProcessingDurationMs) { this.totalProcessingDurationMs = totalProcessingDurationMs; }

    public Instant getFirstProcessedAt() { return firstProcessedAt; }
    public void setFirstProcessedAt(Instant firstProcessedAt) { this.firstProcessedAt = firstProcessedAt; }

    public Instant getLastProcessedAt() { return lastProcessedAt; }
    public void setLastProcessedAt(Instant lastProcessedAt) { this.lastProcessedAt = lastProcessedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
