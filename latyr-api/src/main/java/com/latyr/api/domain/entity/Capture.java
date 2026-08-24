package com.latyr.api.domain.entity;

import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.Intent;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "captures")
public class Capture {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "canonical_source_id")
    private CanonicalSource canonicalSource;

    @Enumerated(EnumType.STRING)
    @Column(name = "content_type", nullable = false, length = 32)
    private ContentType contentType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private CaptureStatus status = CaptureStatus.PENDING;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Enumerated(EnumType.STRING)
    @Column(name = "intent", length = 32)
    private Intent intent;

    @Column(name = "category", length = 64)
    private String category;

    @Column(name = "original_caption", columnDefinition = "TEXT")
    private String originalCaption;

    @Column(name = "audio_transcript", columnDefinition = "TEXT")
    private String audioTranscript;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "notification_copies", nullable = false)
    private List<String> notificationCopies = new ArrayList<>();

    @Column(name = "resurface_count", nullable = false)
    private Integer resurfaceCount = 0;

    @Column(name = "scraping_duration_ms")
    private Integer scrapingDurationMs;

    @Column(name = "ai_inference_duration_ms")
    private Integer aiInferenceDurationMs;

    @Column(name = "total_processing_duration_ms")
    private Integer totalProcessingDurationMs;

    @Column(name = "scheduled_resurface_at")
    private Instant scheduledResurfaceAt;

    @Column(name = "last_resurfaced_at")
    private Instant lastResurfacedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void onPreUpdate() {
        this.updatedAt = Instant.now();
    }

    public Capture() {}

    public Capture(User user, ContentType contentType) {
        this.user = user;
        this.contentType = contentType;
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public CanonicalSource getCanonicalSource() { return canonicalSource; }
    public void setCanonicalSource(CanonicalSource canonicalSource) { this.canonicalSource = canonicalSource; }

    public ContentType getContentType() { return contentType; }
    public void setContentType(ContentType contentType) { this.contentType = contentType; }

    public CaptureStatus getStatus() { return status; }
    public void setStatus(CaptureStatus status) { this.status = status; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public Intent getIntent() { return intent; }
    public void setIntent(Intent intent) { this.intent = intent; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getOriginalCaption() { return originalCaption; }
    public void setOriginalCaption(String originalCaption) { this.originalCaption = originalCaption; }

    public String getAudioTranscript() { return audioTranscript; }
    public void setAudioTranscript(String audioTranscript) { this.audioTranscript = audioTranscript; }

    public List<String> getNotificationCopies() { return notificationCopies; }
    public void setNotificationCopies(List<String> notificationCopies) { this.notificationCopies = notificationCopies; }

    public Integer getResurfaceCount() { return resurfaceCount; }
    public void setResurfaceCount(Integer resurfaceCount) { this.resurfaceCount = resurfaceCount; }

    public Integer getScrapingDurationMs() { return scrapingDurationMs; }
    public void setScrapingDurationMs(Integer scrapingDurationMs) { this.scrapingDurationMs = scrapingDurationMs; }

    public Integer getAiInferenceDurationMs() { return aiInferenceDurationMs; }
    public void setAiInferenceDurationMs(Integer aiInferenceDurationMs) { this.aiInferenceDurationMs = aiInferenceDurationMs; }

    public Integer getTotalProcessingDurationMs() { return totalProcessingDurationMs; }
    public void setTotalProcessingDurationMs(Integer totalProcessingDurationMs) { this.totalProcessingDurationMs = totalProcessingDurationMs; }

    public Instant getScheduledResurfaceAt() { return scheduledResurfaceAt; }
    public void setScheduledResurfaceAt(Instant scheduledResurfaceAt) { this.scheduledResurfaceAt = scheduledResurfaceAt; }

    public Instant getLastResurfacedAt() { return lastResurfacedAt; }
    public void setLastResurfacedAt(Instant lastResurfacedAt) { this.lastResurfacedAt = lastResurfacedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
