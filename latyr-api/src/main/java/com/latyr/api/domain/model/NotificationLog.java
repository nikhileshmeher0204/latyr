package com.latyr.api.domain.model;

import java.time.Instant;
import java.util.UUID;

public class NotificationLog {

    private UUID id;
    private UUID userId;
    private UUID captureId;
    private String notificationType;
    private String sentCopy;
    private String deliveryStatus = "PENDING";
    private int attemptNumber = 1;
    private Instant sentAt = Instant.now();

    public NotificationLog() {}

    public NotificationLog(UUID userId, UUID captureId, String notificationType, String sentCopy) {
        this.userId = userId;
        this.captureId = captureId;
        this.notificationType = notificationType;
        this.sentCopy = sentCopy;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getCaptureId() { return captureId; }
    public void setCaptureId(UUID captureId) { this.captureId = captureId; }

    public String getNotificationType() { return notificationType; }
    public void setNotificationType(String notificationType) { this.notificationType = notificationType; }

    public String getSentCopy() { return sentCopy; }
    public void setSentCopy(String sentCopy) { this.sentCopy = sentCopy; }

    public String getDeliveryStatus() { return deliveryStatus; }
    public void setDeliveryStatus(String deliveryStatus) { this.deliveryStatus = deliveryStatus; }

    public int getAttemptNumber() { return attemptNumber; }
    public void setAttemptNumber(int attemptNumber) { this.attemptNumber = attemptNumber; }

    public Instant getSentAt() { return sentAt; }
    public void setSentAt(Instant sentAt) { this.sentAt = sentAt; }
}
