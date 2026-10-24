package com.latyr.api.domain.model;

import java.time.Instant;
import java.util.UUID;

public class CaptureQuotaReservation {
    private UUID userId;
    private UUID canonicalSourceId;
    private UUID captureId;
    private String state;
    private boolean grandfathered;
    private Instant quotaCycleEnd;

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getCanonicalSourceId() { return canonicalSourceId; }
    public void setCanonicalSourceId(UUID canonicalSourceId) { this.canonicalSourceId = canonicalSourceId; }
    public UUID getCaptureId() { return captureId; }
    public void setCaptureId(UUID captureId) { this.captureId = captureId; }
    public String getState() { return state; }
    public void setState(String state) { this.state = state; }
    public boolean isGrandfathered() { return grandfathered; }
    public void setGrandfathered(boolean grandfathered) { this.grandfathered = grandfathered; }
    public Instant getQuotaCycleEnd() { return quotaCycleEnd; }
    public void setQuotaCycleEnd(Instant quotaCycleEnd) { this.quotaCycleEnd = quotaCycleEnd; }
}
