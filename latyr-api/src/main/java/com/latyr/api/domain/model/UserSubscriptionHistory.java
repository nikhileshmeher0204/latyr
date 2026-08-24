package com.latyr.api.domain.model;

import com.latyr.api.domain.enums.SubscriptionEventType;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public class UserSubscriptionHistory {

    private UUID id;
    private UUID userId;
    private String fromTier;
    private String toTier;
    private SubscriptionEventType eventType;
    private BigDecimal amountPaid = BigDecimal.ZERO;
    private String currency = "USD";
    private String providerTransactionId;
    private Instant eventTimestamp = Instant.now();

    public UserSubscriptionHistory() {}

    public UserSubscriptionHistory(UUID userId, String fromTier, String toTier, SubscriptionEventType eventType) {
        this.userId = userId;
        this.fromTier = fromTier;
        this.toTier = toTier;
        this.eventType = eventType;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getFromTier() { return fromTier; }
    public void setFromTier(String fromTier) { this.fromTier = fromTier; }

    public String getToTier() { return toTier; }
    public void setToTier(String toTier) { this.toTier = toTier; }

    public SubscriptionEventType getEventType() { return eventType; }
    public void setEventType(SubscriptionEventType eventType) { this.eventType = eventType; }

    public BigDecimal getAmountPaid() { return amountPaid; }
    public void setAmountPaid(BigDecimal amountPaid) { this.amountPaid = amountPaid; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getProviderTransactionId() { return providerTransactionId; }
    public void setProviderTransactionId(String providerTransactionId) { this.providerTransactionId = providerTransactionId; }

    public Instant getEventTimestamp() { return eventTimestamp; }
    public void setEventTimestamp(Instant eventTimestamp) { this.eventTimestamp = eventTimestamp; }
}
