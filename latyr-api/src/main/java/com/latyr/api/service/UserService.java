package com.latyr.api.service;

import com.latyr.api.domain.enums.Language;
import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.domain.model.User;
import com.latyr.api.domain.model.UserSubscription;
import com.latyr.api.dto.UpdatePreferencesRequest;
import com.latyr.api.dto.UserProfileResponse;
import com.latyr.api.exception.ResourceNotFoundException;
import com.latyr.api.mapper.UserMapper;
import com.latyr.api.security.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Service
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserMapper userMapper;
    private final SubscriptionQuotaService subscriptionQuotaService;

    public UserService(UserMapper userMapper, SubscriptionQuotaService subscriptionQuotaService) {
        this.userMapper = userMapper;
        this.subscriptionQuotaService = subscriptionQuotaService;
    }

    @Transactional
    public AuthenticatedUser getOrProvisionUser(String firebaseUid, String email, String displayName, String photoUrl) {
        Optional<User> existingUserOpt = userMapper.findByFirebaseUid(firebaseUid);

        User user;
        if (existingUserOpt.isPresent()) {
            user = existingUserOpt.get();
            boolean needsUpdate = false;

            if (email != null && !email.equals(user.getEmail())) {
                user.setEmail(email);
                needsUpdate = true;
            }
            if (displayName != null && !displayName.equals(user.getDisplayName())) {
                user.setDisplayName(displayName);
                needsUpdate = true;
            }
            if (photoUrl != null && !photoUrl.equals(user.getPhotoUrl())) {
                user.setPhotoUrl(photoUrl);
                needsUpdate = true;
            }
            if (needsUpdate) {
                userMapper.update(user);
            }
        } else {
            log.info("Auto-provisioning new user for Firebase UID: {}", firebaseUid);
            user = new User();
            user.setId(UUID.randomUUID());
            user.setFirebaseUid(firebaseUid);
            user.setEmail(email != null ? email : firebaseUid + "@latyr.internal");
            user.setDisplayName(displayName != null ? displayName : "Latyr User");
            user.setPhotoUrl(photoUrl);
            user.setTimezone("UTC");
            user.setLanguage(Language.ENGLISH);
            user.setCreatedAt(Instant.now());
            user.setUpdatedAt(Instant.now());

            userMapper.insert(user);
            subscriptionQuotaService.createDefaultFreeSubscription(user.getId());
        }

        UserSubscription sub = subscriptionQuotaService.getSubscription(user.getId());
        return new AuthenticatedUser(
                user.getId(),
                user.getFirebaseUid(),
                user.getEmail(),
                user.getDisplayName(),
                user.getPhotoUrl(),
                sub != null ? sub.getPlanTier() : PlanTier.FREE
        );
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getUserProfile(UUID userId) {
        User user = userMapper.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + userId));
        UserSubscription sub = subscriptionQuotaService.getSubscription(userId);

        return UserProfileResponse.of(
                user.getId(),
                user.getEmail(),
                user.getDisplayName(),
                user.getPhotoUrl(),
                user.getTimezone(),
                user.getLanguage(),
                sub.getPlanTier(),
                sub.getMonthlyCaptureCount(),
                sub.getQuotaLimit(),
                sub.getQuotaResetAt(),
                user.getCreatedAt()
        );
    }

    @Transactional
    public UserProfileResponse updatePreferences(UUID userId, UpdatePreferencesRequest request) {
        User user = userMapper.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + userId));

        if (request.timezone() != null && !request.timezone().trim().isEmpty()) {
            user.setTimezone(request.timezone().trim());
        }
        if (request.language() != null) {
            user.setLanguage(request.language());
        }
        if (request.fcmToken() != null) {
            user.setFcmToken(request.fcmToken().trim());
        }

        userMapper.update(user);
        log.info("Updated preferences for user: {}", userId);

        return getUserProfile(userId);
    }
}
