package com.latyr.api.domain.model;

import java.util.Map;
import java.util.UUID;

public class IngestionOutboxEvent {
    private UUID id;
    private UUID userId;
    private String eventType;
    private Map<String,Object> payload;
    private UUID leaseToken;
    private int attemptCount;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }
    public Map<String,Object> getPayload() { return payload; }
    public void setPayload(Map<String,Object> payload) { this.payload = payload; }
    public UUID getLeaseToken() { return leaseToken; }
    public void setLeaseToken(UUID leaseToken) { this.leaseToken = leaseToken; }
    public int getAttemptCount() { return attemptCount; }
    public void setAttemptCount(int attemptCount) { this.attemptCount = attemptCount; }
}
