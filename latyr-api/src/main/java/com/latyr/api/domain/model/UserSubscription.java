package com.latyr.api.domain.model;

import com.latyr.api.domain.enums.PlanTier;
import java.time.Instant;
import java.util.UUID;

public class UserSubscription {

    private UUID id;
    private UUID userId;
    private PlanTier planTier = PlanTier.FREE;
    private int monthlyCaptureCount = 0;
    private int quotaLimit = 30;
    private Instant quotaResetAt;
    private Instant expiresAt;
    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    public UserSubscription() {}

    public UserSubscription(UUID userId, PlanTier planTier, int quotaLimit) {
        this.userId = userId;
        this.planTier = planTier;
        this.quotaLimit = quotaLimit;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public PlanTier getPlanTier() { return planTier; }
    public void setPlanTier(PlanTier planTier) { this.planTier = planTier; }

    public int getMonthlyCaptureCount() { return monthlyCaptureCount; }
    public void setMonthlyCaptureCount(int monthlyCaptureCount) { this.monthlyCaptureCount = monthlyCaptureCount; }

    public int getQuotaLimit() { return quotaLimit; }
    public void setQuotaLimit(int quotaLimit) { this.quotaLimit = quotaLimit; }

    public Instant getQuotaResetAt() { return quotaResetAt; }
    public void setQuotaResetAt(Instant quotaResetAt) { this.quotaResetAt = quotaResetAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
