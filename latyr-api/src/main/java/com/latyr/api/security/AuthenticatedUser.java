package com.latyr.api.security;

import com.latyr.api.domain.enums.PlanTier;
import java.security.Principal;
import java.util.UUID;

public class AuthenticatedUser implements Principal {

    private final UUID userId;
    private final String firebaseUid;
    private final String email;
    private final String displayName;
    private final String photoUrl;
    private final PlanTier planTier;

    public AuthenticatedUser(UUID userId, String firebaseUid, String email) {
        this(userId, firebaseUid, email, null, null, PlanTier.FREE);
    }

    public AuthenticatedUser(UUID userId, String firebaseUid, String email, String displayName, String photoUrl, PlanTier planTier) {
        this.userId = userId;
        this.firebaseUid = firebaseUid;
        this.email = email;
        this.displayName = displayName;
        this.photoUrl = photoUrl;
        this.planTier = planTier != null ? planTier : PlanTier.FREE;
    }

    @Override
    public String getName() {
        return firebaseUid;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getFirebaseUid() {
        return firebaseUid;
    }

    public String getEmail() {
        return email;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    public PlanTier getPlanTier() {
        return planTier;
    }

    public boolean isPro() {
        return PlanTier.PRO.equals(planTier);
    }
}
