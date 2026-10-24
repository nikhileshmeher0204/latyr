package com.latyr.api;

import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.domain.model.UserSubscription;
import com.latyr.api.mapper.*;
import com.latyr.api.service.SubscriptionQuotaService;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class SubscriptionQuotaServiceTest {
    private final UserSubscriptionMapper mapper = mock(UserSubscriptionMapper.class);
    private final SubscriptionQuotaService service = new SubscriptionQuotaService(mapper,
            mock(UserSubscriptionHistoryMapper.class), mock(UserMapper.class));

    @Test
    void quotaLockUsesLockedRowAndDoesNotIncrementOnAdmission() {
        UUID user = UUID.randomUUID();
        UserSubscription sub = new UserSubscription(user, PlanTier.FREE, 30);
        sub.setMonthlyCaptureCount(5);
        sub.setQuotaResetAt(Instant.now().plus(15, ChronoUnit.DAYS));
        when(mapper.lockByUserId(user)).thenReturn(Optional.of(sub));
        assertSame(sub, service.lockForQuota(user));
        assertEquals(5, sub.getMonthlyCaptureCount());
        verify(mapper).ensureDefault(user, 30);
        verify(mapper).lockByUserId(user);
        verify(mapper, never()).findByUserId(any());
        verify(mapper, never()).incrementFinalizedCaptureCount(any());
    }

    @Test
    void expiredCycleResetsLockedCounterWithoutOverwritingPlanFields() {
        UUID user = UUID.randomUUID();
        UserSubscription sub = new UserSubscription(user, PlanTier.PRO, 1000);
        sub.setMonthlyCaptureCount(30);
        sub.setQuotaResetAt(Instant.now().minus(1, ChronoUnit.DAYS));
        when(mapper.lockByUserId(user)).thenReturn(Optional.of(sub));
        service.lockForQuota(user);
        assertEquals(0, sub.getMonthlyCaptureCount());
        assertEquals(PlanTier.PRO, sub.getPlanTier());
        verify(mapper).resetQuotaCycle(eq(user), any(Instant.class));
        verify(mapper, never()).update(any());
    }

    @Test
    void concurrentDefaultInsertReturnsExistingSubscriptionWithoutResettingIt() {
        UUID user = UUID.randomUUID();
        UserSubscription existing = new UserSubscription(user, PlanTier.PRO, 1000);
        existing.setMonthlyCaptureCount(9);
        when(mapper.insert(any())).thenReturn(0);
        when(mapper.findByUserId(user)).thenReturn(Optional.of(existing));
        assertSame(existing, service.createDefaultFreeSubscription(user));
        assertEquals(9, existing.getMonthlyCaptureCount());
        verify(mapper, never()).update(any());
    }
}
