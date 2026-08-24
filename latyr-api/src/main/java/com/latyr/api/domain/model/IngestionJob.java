package com.latyr.api.domain.model;

import com.latyr.api.domain.enums.JobStatus;
import com.latyr.api.domain.enums.SourceType;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class IngestionJob {

    private UUID id;
    private UUID captureId;
    private UUID userId;
    private SourceType sourceType;
    private Map<String, Object> payload = new HashMap<>();
    private JobStatus status = JobStatus.PENDING;
    private int attemptCount = 0;
    private int maxAttempts = 3;
    private Instant lockedAt;
    private String lockedBy;
    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    public IngestionJob() {}

    public IngestionJob(UUID captureId, UUID userId, SourceType sourceType, Map<String, Object> payload) {
        this.captureId = captureId;
        this.userId = userId;
        this.sourceType = sourceType;
        this.payload = payload;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getCaptureId() { return captureId; }
    public void setCaptureId(UUID captureId) { this.captureId = captureId; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public SourceType getSourceType() { return sourceType; }
    public void setSourceType(SourceType sourceType) { this.sourceType = sourceType; }

    public Map<String, Object> getPayload() { return payload; }
    public void setPayload(Map<String, Object> payload) { this.payload = payload; }

    public JobStatus getStatus() { return status; }
    public void setStatus(JobStatus status) { this.status = status; }

    public int getAttemptCount() { return attemptCount; }
    public void setAttemptCount(int attemptCount) { this.attemptCount = attemptCount; }

    public int getMaxAttempts() { return maxAttempts; }
    public void setMaxAttempts(int maxAttempts) { this.maxAttempts = maxAttempts; }

    public Instant getLockedAt() { return lockedAt; }
    public void setLockedAt(Instant lockedAt) { this.lockedAt = lockedAt; }

    public String getLockedBy() { return lockedBy; }
    public void setLockedBy(String lockedBy) { this.lockedBy = lockedBy; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
