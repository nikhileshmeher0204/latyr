package com.latyr.api.domain.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "notification_logs")
public class NotificationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "capture_id", nullable = false)
    private Capture capture;

    @Column(name = "notification_type", nullable = false, length = 32)
    private String notificationType;

    @Column(name = "sent_copy", nullable = false, columnDefinition = "TEXT")
    private String sentCopy;

    @Column(name = "delivery_status", nullable = false, length = 32)
    private String deliveryStatus = "DELIVERED";

    @Column(name = "attempt_number", nullable = false)
    private Integer attemptNumber = 1;

    @Column(name = "sent_at", nullable = false, updatable = false)
    private Instant sentAt = Instant.now();

    public NotificationLog() {}

    public NotificationLog(User user, Capture capture, String notificationType, String sentCopy) {
        this.user = user;
        this.capture = capture;
        this.notificationType = notificationType;
        this.sentCopy = sentCopy;
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Capture getCapture() { return capture; }
    public void setCapture(Capture capture) { this.capture = capture; }

    public String getNotificationType() { return notificationType; }
    public void setNotificationType(String notificationType) { this.notificationType = notificationType; }

    public String getSentCopy() { return sentCopy; }
    public void setSentCopy(String sentCopy) { this.sentCopy = sentCopy; }

    public String getDeliveryStatus() { return deliveryStatus; }
    public void setDeliveryStatus(String deliveryStatus) { this.deliveryStatus = deliveryStatus; }

    public Integer getAttemptNumber() { return attemptNumber; }
    public void setAttemptNumber(Integer attemptNumber) { this.attemptNumber = attemptNumber; }

    public Instant getSentAt() { return sentAt; }
    public void setSentAt(Instant sentAt) { this.sentAt = sentAt; }
}
