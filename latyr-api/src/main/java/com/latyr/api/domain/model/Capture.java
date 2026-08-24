package com.latyr.api.domain.model;

import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.Intent;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class Capture {

    private UUID id;
    private UUID userId;
    private UUID canonicalSourceId;
    private ContentType contentType;
    private CaptureStatus status = CaptureStatus.PENDING;
    private Intent intent;
    private String category;
    private String originalCaption;
    private String audioTranscript;
    private List<String> notificationCopies = new ArrayList<>();
    private int resurfaceCount = 0;
    private Long durationMs;
    private Integer videoDurationSec;
    private Instant scheduledResurfaceAt;
    private Instant lastResurfacedAt;
    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    public Capture() {}

    public Capture(UUID userId, ContentType contentType, CaptureStatus status) {
        this.userId = userId;
        this.contentType = contentType;
        this.status = status;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getCanonicalSourceId() { return canonicalSourceId; }
    public void setCanonicalSourceId(UUID canonicalSourceId) { this.canonicalSourceId = canonicalSourceId; }

    public ContentType getContentType() { return contentType; }
    public void setContentType(ContentType contentType) { this.contentType = contentType; }

    public CaptureStatus getStatus() { return status; }
    public void setStatus(CaptureStatus status) { this.status = status; }

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

    public int getResurfaceCount() { return resurfaceCount; }
    public void setResurfaceCount(int resurfaceCount) { this.resurfaceCount = resurfaceCount; }

    public Long getDurationMs() { return durationMs; }
    public void setDurationMs(Long durationMs) { this.durationMs = durationMs; }

    public Integer getVideoDurationSec() { return videoDurationSec; }
    public void setVideoDurationSec(Integer videoDurationSec) { this.videoDurationSec = videoDurationSec; }

    public Instant getScheduledResurfaceAt() { return scheduledResurfaceAt; }
    public void setScheduledResurfaceAt(Instant scheduledResurfaceAt) { this.scheduledResurfaceAt = scheduledResurfaceAt; }

    public Instant getLastResurfacedAt() { return lastResurfacedAt; }
    public void setLastResurfacedAt(Instant lastResurfacedAt) { this.lastResurfacedAt = lastResurfacedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
