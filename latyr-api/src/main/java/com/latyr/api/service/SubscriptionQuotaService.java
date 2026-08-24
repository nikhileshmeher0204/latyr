package com.latyr.api.service;

import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.domain.enums.SubscriptionEventType;
import com.latyr.api.domain.model.User;
import com.latyr.api.domain.model.UserSubscription;
import com.latyr.api.domain.model.UserSubscriptionHistory;
import com.latyr.api.exception.QuotaExceededException;
import com.latyr.api.mapper.UserMapper;
import com.latyr.api.mapper.UserSubscriptionHistoryMapper;
import com.latyr.api.mapper.UserSubscriptionMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class SubscriptionQuotaService {

    private static final Logger log = LoggerFactory.getLogger(SubscriptionQuotaService.class);
    private static final int DEFAULT_FREE_QUOTA = 30;
    private static final int PRO_QUOTA = 1000;

    private final UserSubscriptionMapper subscriptionMapper;
    private final UserSubscriptionHistoryMapper historyMapper;
    private final UserMapper userMapper;

    public SubscriptionQuotaService(
            UserSubscriptionMapper subscriptionMapper,
            UserSubscriptionHistoryMapper historyMapper,
            UserMapper userMapper) {
        this.subscriptionMapper = subscriptionMapper;
        this.historyMapper = historyMapper;
        this.userMapper = userMapper;
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

        // Unlimited / 1000 if PRO
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

    @SuppressWarnings("unchecked")
    @Transactional
    public void handleRevenueCatEvent(Map<String, Object> webhookPayload) {
        if (webhookPayload == null || !webhookPayload.containsKey("event")) {
            log.warn("Ignored empty or invalid RevenueCat webhook payload");
            return;
        }

        Map<String, Object> event = (Map<String, Object>) webhookPayload.get("event");
        String eventTypeStr = (String) event.get("type");
        String appUserId = (String) event.get("app_user_id");

        if (eventTypeStr == null || appUserId == null) {
            log.warn("RevenueCat event missing type or app_user_id: {}", event);
            return;
        }

        // Resolve User
        UUID userId = null;
        try {
            userId = UUID.fromString(appUserId);
        } catch (IllegalArgumentException ignored) {
            // Might be firebaseUid
            Optional<User> userOpt = userMapper.findByFirebaseUid(appUserId);
            if (userOpt.isPresent()) {
                userId = userOpt.get().getId();
            }
        }

        if (userId == null) {
            Optional<User> userOpt = userMapper.findByFirebaseUid(appUserId);
            if (userOpt.isPresent()) {
                userId = userOpt.get().getId();
            } else {
                log.warn("Could not find user associated with RevenueCat app_user_id: {}", appUserId);
                return;
            }
        }

        UserSubscription subscription = getSubscription(userId);
        String fromTier = subscription.getPlanTier().name();

        SubscriptionEventType eventType;
        PlanTier newTier;
        int newQuota;
        Instant expiresAt = null;

        Object expMsObj = event.get("expiration_at_ms");
        if (expMsObj instanceof Number num) {
            expiresAt = Instant.ofEpochMilli(num.longValue());
        }

        BigDecimal price = BigDecimal.ZERO;
        Object priceObj = event.get("price_in_purchased_currency");
        if (priceObj instanceof Number num) {
            price = BigDecimal.valueOf(num.doubleValue());
        }

        String currency = (String) event.getOrDefault("currency", "USD");
        String transactionId = (String) event.get("transaction_id");

        switch (eventTypeStr.toUpperCase()) {
            case "INITIAL_PURCHASE":
            case "RENEWAL":
            case "PRODUCT_CHANGE":
                newTier = PlanTier.PRO;
                newQuota = PRO_QUOTA;
                eventType = eventTypeStr.equalsIgnoreCase("RENEWAL") ? SubscriptionEventType.RENEWAL : SubscriptionEventType.UPGRADE;
                break;

            case "CANCELLATION":
            case "EXPIRATION":
                newTier = PlanTier.FREE;
                newQuota = DEFAULT_FREE_QUOTA;
                expiresAt = null;
                eventType = eventTypeStr.equalsIgnoreCase("CANCELLATION") ? SubscriptionEventType.CANCELLATION : SubscriptionEventType.DOWNGRADE;
                break;

            default:
                log.info("Unhandled RevenueCat event type: {}", eventTypeStr);
                return;
        }

        // Update Subscription
        subscription.setPlanTier(newTier);
        subscription.setQuotaLimit(newQuota);
        subscription.setExpiresAt(expiresAt);
        subscription.setUpdatedAt(Instant.now());
        subscriptionMapper.update(subscription);

        // Record Audit History
        UserSubscriptionHistory history = new UserSubscriptionHistory();
        history.setUserId(userId);
        history.setFromTier(fromTier);
        history.setToTier(newTier.name());
        history.setEventType(eventType);
        history.setAmountPaid(price);
        history.setCurrency(currency);
        history.setProviderTransactionId(transactionId);
        history.setEventTimestamp(Instant.now());
        historyMapper.insert(history);

        log.info("Processed RevenueCat billing event '{}' for user {}: {} -> {}", eventTypeStr, userId, fromTier, newTier.name());
    }
}
