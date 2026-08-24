package com.latyr.api.dto;

import com.latyr.api.domain.enums.Language;
import com.latyr.api.domain.enums.PlanTier;

import java.time.Instant;
import java.util.UUID;

public record UserProfileResponse(
        UUID id,
        String email,
        String displayName,
        String photoUrl,
        String timezone,
        Language language,
        PlanTier planTier,
        int monthlyCaptureCount,
        int quotaLimit,
        int remainingQuota,
        Instant quotaResetAt,
        Instant createdAt
) {
    public static UserProfileResponse of(
            UUID id,
            String email,
            String displayName,
            String photoUrl,
            String timezone,
            Language language,
            PlanTier planTier,
            int monthlyCaptureCount,
            int quotaLimit,
            Instant quotaResetAt,
            Instant createdAt
    ) {
        int remaining = Math.max(0, quotaLimit - monthlyCaptureCount);
        return new UserProfileResponse(
                id,
                email,
                displayName,
                photoUrl,
                timezone,
                language,
                planTier,
                monthlyCaptureCount,
                quotaLimit,
                remaining,
                quotaResetAt,
                createdAt
        );
    }
}
