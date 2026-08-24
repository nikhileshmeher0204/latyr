package com.latyr.api.service;

import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.domain.model.UserSubscription;
import com.latyr.api.exception.QuotaExceededException;
import com.latyr.api.exception.ResourceNotFoundException;
import com.latyr.api.mapper.UserSubscriptionMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.UUID;

@Service
public class SubscriptionQuotaService {

    private static final Logger log = LoggerFactory.getLogger(SubscriptionQuotaService.class);
    private static final int DEFAULT_FREE_QUOTA = 30;

    private final UserSubscriptionMapper subscriptionMapper;

    public SubscriptionQuotaService(UserSubscriptionMapper subscriptionMapper) {
        this.subscriptionMapper = subscriptionMapper;
    }

    public UserSubscription getSubscription(UUID userId) {
        return subscriptionMapper.findByUserId(userId)
                .orElseGet(() -> createDefaultFreeSubscription(userId));
    }

    @Transactional
    public UserSubscription createDefaultFreeSubscription(UUID userId) {
        UserSubscription sub = new UserSubscription();
        sub.setId(UUID.randomUUID());
        sub.setUserId(userId);
        sub.setPlanTier(PlanTier.FREE);
        sub.setMonthlyCaptureCount(0);
        sub.setQuotaLimit(DEFAULT_FREE_QUOTA);
        sub.setQuotaResetAt(Instant.now().plus(30, ChronoUnit.DAYS));
        sub.setCreatedAt(Instant.now());
        sub.setUpdatedAt(Instant.now());
        subscriptionMapper.insert(sub);
        return sub;
    }

    @Transactional
    public void verifyAndIncrementQuota(UUID userId) {
        UserSubscription sub = getSubscription(userId);

        // Check if billing/monthly cycle reset is due
        if (sub.getQuotaResetAt() != null && Instant.now().isAfter(sub.getQuotaResetAt())) {
            log.info("Resetting monthly capture quota for user {}", userId);
            sub.setMonthlyCaptureCount(0);
            sub.setQuotaResetAt(Instant.now().plus(30, ChronoUnit.DAYS));
            subscriptionMapper.update(sub);
        }

        // Unlimited if PRO
        if (PlanTier.PRO.equals(sub.getPlanTier())) {
            subscriptionMapper.incrementMonthlyCaptureCountIfWithinQuota(userId);
            return;
        }

        // Check Free Tier Quota
        if (sub.getMonthlyCaptureCount() >= sub.getQuotaLimit()) {
            log.warn("User {} exceeded capture quota ({}/{})", userId, sub.getMonthlyCaptureCount(), sub.getQuotaLimit());
            throw new QuotaExceededException(
                    "Monthly capture quota exceeded. Upgrade to PRO for unlimited captures.",
                    Map.of(
                            "quota_limit", sub.getQuotaLimit(),
                            "monthly_capture_count", sub.getMonthlyCaptureCount(),
                            "quota_reset_at", sub.getQuotaResetAt() != null ? sub.getQuotaResetAt().toString() : "",
                            "upgrade_url", "https://latyr.com/upgrade"
                    )
            );
        }

        // Atomically increment quota
        int updated = subscriptionMapper.incrementMonthlyCaptureCountIfWithinQuota(userId);
        if (updated == 0) {
            // Fallback in case of boundary concurrency race condition
            sub = getSubscription(userId);
            if (sub.getMonthlyCaptureCount() >= sub.getQuotaLimit()) {
                throw new QuotaExceededException(
                        "Monthly capture quota exceeded. Upgrade to PRO for unlimited captures.",
                        Map.of("quota_limit", sub.getQuotaLimit())
                );
            }
            sub.setMonthlyCaptureCount(sub.getMonthlyCaptureCount() + 1);
            subscriptionMapper.update(sub);
        }
    }
}
