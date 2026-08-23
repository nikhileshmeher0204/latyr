package com.latyr.latyr_api.domain.entity;

import com.latyr.latyr_api.domain.enums.PlanTier;
import com.latyr.latyr_api.domain.enums.SubscriptionEventType;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_subscription_history")
public class UserSubscriptionHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "from_tier", nullable = false, length = 32)
    private PlanTier fromTier;

    @Enumerated(EnumType.STRING)
    @Column(name = "to_tier", nullable = false, length = 32)
    private PlanTier toTier;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 32)
    private SubscriptionEventType eventType;

    @Column(name = "amount_paid", precision = 10, scale = 2)
    private BigDecimal amountPaid = BigDecimal.ZERO;

    @Column(name = "currency", length = 8)
    private String currency = "USD";

    @Column(name = "provider_transaction_id", length = 255)
    private String providerTransactionId;

    @Column(name = "event_timestamp", nullable = false, updatable = false)
    private Instant eventTimestamp = Instant.now();

    public UserSubscriptionHistory() {}

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public PlanTier getFromTier() { return fromTier; }
    public void setFromTier(PlanTier fromTier) { this.fromTier = fromTier; }

    public PlanTier getToTier() { return toTier; }
    public void setToTier(PlanTier toTier) { this.toTier = toTier; }

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
