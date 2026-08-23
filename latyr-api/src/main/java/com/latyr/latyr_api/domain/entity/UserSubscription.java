package com.latyr.latyr_api.domain.entity;

import com.latyr.latyr_api.domain.enums.PlanTier;
import jakarta.persistence.*;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Entity
@Table(name = "user_subscriptions")
public class UserSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "plan_tier", nullable = false, length = 32)
    private PlanTier planTier = PlanTier.FREE;

    @Column(name = "monthly_capture_count", nullable = false)
    private Integer monthlyCaptureCount = 0;

    @Column(name = "quota_limit", nullable = false)
    private Integer quotaLimit = 30;

    @Column(name = "quota_reset_at", nullable = false)
    private Instant quotaResetAt = Instant.now().plus(30, ChronoUnit.DAYS);

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void onPreUpdate() {
        this.updatedAt = Instant.now();
    }

    public UserSubscription() {}

    public UserSubscription(User user) {
        this.user = user;
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public PlanTier getPlanTier() { return planTier; }
    public void setPlanTier(PlanTier planTier) { this.planTier = planTier; }

    public Integer getMonthlyCaptureCount() { return monthlyCaptureCount; }
    public void setMonthlyCaptureCount(Integer monthlyCaptureCount) { this.monthlyCaptureCount = monthlyCaptureCount; }

    public Integer getQuotaLimit() { return quotaLimit; }
    public void setQuotaLimit(Integer quotaLimit) { this.quotaLimit = quotaLimit; }

    public Instant getQuotaResetAt() { return quotaResetAt; }
    public void setQuotaResetAt(Instant quotaResetAt) { this.quotaResetAt = quotaResetAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
