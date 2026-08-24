package com.latyr.api;

import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.domain.model.UserSubscription;
import com.latyr.api.exception.QuotaExceededException;
import com.latyr.api.mapper.UserSubscriptionMapper;
import com.latyr.api.service.SubscriptionQuotaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class SubscriptionQuotaServiceTest {

    private UserSubscriptionMapper subscriptionMapper;
    private com.latyr.api.mapper.UserSubscriptionHistoryMapper historyMapper;
    private com.latyr.api.mapper.UserMapper userMapper;
    private SubscriptionQuotaService quotaService;

    @BeforeEach
    void setUp() {
        subscriptionMapper = Mockito.mock(UserSubscriptionMapper.class);
        historyMapper = Mockito.mock(com.latyr.api.mapper.UserSubscriptionHistoryMapper.class);
        userMapper = Mockito.mock(com.latyr.api.mapper.UserMapper.class);
        quotaService = new SubscriptionQuotaService(subscriptionMapper, historyMapper, userMapper);
    }

    @Test
    @DisplayName("Should successfully increment quota for free tier user under limit")
    void testVerifyAndIncrementQuota_Success() {
        UUID userId = UUID.randomUUID();
        UserSubscription sub = new UserSubscription(userId, PlanTier.FREE, 30);
        sub.setMonthlyCaptureCount(5);
        sub.setQuotaResetAt(Instant.now().plus(15, ChronoUnit.DAYS));

        when(subscriptionMapper.findByUserId(userId)).thenReturn(Optional.of(sub));
        when(subscriptionMapper.incrementMonthlyCaptureCountIfWithinQuota(userId)).thenReturn(1);

        assertDoesNotThrow(() -> quotaService.verifyAndIncrementQuota(userId));
        verify(subscriptionMapper, times(1)).incrementMonthlyCaptureCountIfWithinQuota(userId);
    }

    @Test
    @DisplayName("Should throw QuotaExceededException when free tier limit of 30 is reached")
    void testVerifyAndIncrementQuota_Exceeded() {
        UUID userId = UUID.randomUUID();
        UserSubscription sub = new UserSubscription(userId, PlanTier.FREE, 30);
        sub.setMonthlyCaptureCount(30);
        sub.setQuotaResetAt(Instant.now().plus(10, ChronoUnit.DAYS));

        when(subscriptionMapper.findByUserId(userId)).thenReturn(Optional.of(sub));

        QuotaExceededException ex = assertThrows(
                QuotaExceededException.class,
                () -> quotaService.verifyAndIncrementQuota(userId)
        );

        assertEquals("QUOTA_EXCEEDED", ex.getErrorCode());
        verify(subscriptionMapper, never()).incrementMonthlyCaptureCountIfWithinQuota(userId);
    }

    @Test
    @DisplayName("Should reset monthly capture count if quotaResetAt timestamp has expired")
    void testVerifyAndIncrementQuota_ResetExpiredCycle() {
        UUID userId = UUID.randomUUID();
        UserSubscription sub = new UserSubscription(userId, PlanTier.FREE, 30);
        sub.setMonthlyCaptureCount(30);
        sub.setQuotaResetAt(Instant.now().minus(1, ChronoUnit.DAYS)); // Past expiration

        when(subscriptionMapper.findByUserId(userId)).thenReturn(Optional.of(sub));
        when(subscriptionMapper.incrementMonthlyCaptureCountIfWithinQuota(userId)).thenReturn(1);

        assertDoesNotThrow(() -> quotaService.verifyAndIncrementQuota(userId));
        assertEquals(0, sub.getMonthlyCaptureCount());
        verify(subscriptionMapper, times(1)).update(sub);
    }
}
