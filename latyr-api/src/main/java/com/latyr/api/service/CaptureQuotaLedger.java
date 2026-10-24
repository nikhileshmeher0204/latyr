package com.latyr.api.service;

import com.latyr.api.domain.model.CaptureQuotaReservation;
import com.latyr.api.domain.model.UserSubscription;
import com.latyr.api.exception.QuotaExceededException;
import com.latyr.api.mapper.CaptureQuotaLedgerMapper;
import com.latyr.api.mapper.UserSubscriptionMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@Transactional(propagation = Propagation.MANDATORY)
public class CaptureQuotaLedger {
    private final CaptureQuotaLedgerMapper ledger;
    private final SubscriptionQuotaService subscriptions;
    private final UserSubscriptionMapper subscriptionMapper;

    public CaptureQuotaLedger(CaptureQuotaLedgerMapper ledger, SubscriptionQuotaService subscriptions,
                              UserSubscriptionMapper subscriptionMapper) {
        this.ledger = ledger;
        this.subscriptions = subscriptions;
        this.subscriptionMapper = subscriptionMapper;
    }

    /** Serialize admission before duplicate detection, including first subscription creation. */
    public void lockAdmission(UUID userId) {
        subscriptions.lockForQuota(userId);
    }

    public void reserveCapture(UUID userId, UUID sourceId, UUID captureId) {
        UserSubscription sub = subscriptions.lockForQuota(userId);
        CaptureQuotaReservation existing = ledger.find(userId, sourceId).orElse(null);
        if (existing != null && "FINALIZED".equals(existing.getState())) {
            ledger.attachFinalized(userId, sourceId, captureId);
            return;
        }
        if (existing != null && "RESERVED".equals(existing.getState())) {
            if (!captureId.equals(existing.getCaptureId())) {
                throw new IllegalStateException("Capture already has a quota reservation");
            }
            return;
        }
        // Outstanding reservations carry across reset boundaries and count toward capacity.
        if (sub.getMonthlyCaptureCount() + ledger.countReservations(userId) >= sub.getQuotaLimit()) {
            throw new QuotaExceededException("Monthly capture quota exceeded for plan " + sub.getPlanTier());
        }
        if (ledger.reserve(userId, sourceId, captureId, sub.getQuotaResetAt()) != 1) {
            throw new IllegalStateException("Quota reservation changed during admission");
        }
    }

    public void finalizeCapture(UUID captureId) {
        CaptureQuotaReservation row = lockReservation(captureId);
        if (row == null || !"RESERVED".equals(row.getState())) return;
        UserSubscription sub = subscriptions.lockForQuota(row.getUserId());
        if (ledger.transition(captureId, "FINALIZED", sub.getQuotaResetAt()) == 1 && !row.isGrandfathered()) {
            if (subscriptionMapper.incrementFinalizedCaptureCount(row.getUserId()) != 1) {
                throw new IllegalStateException("Subscription missing during quota finalization");
            }
        }
    }

    public void releaseCapture(UUID captureId) {
        CaptureQuotaReservation row = lockReservation(captureId);
        if (row != null && "RESERVED".equals(row.getState())) {
            ledger.transition(captureId, "RELEASED", row.getQuotaCycleEnd());
        }
    }

    private CaptureQuotaReservation lockReservation(UUID captureId) {
        CaptureQuotaReservation observed = ledger.findByCaptureId(captureId).orElse(null);
        if (observed == null) return null;
        subscriptions.lockForQuota(observed.getUserId());
        return ledger.findByCaptureId(captureId).orElse(null);
    }
}
