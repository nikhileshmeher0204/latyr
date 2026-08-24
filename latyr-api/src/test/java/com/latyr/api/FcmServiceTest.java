package com.latyr.api;

import com.latyr.api.service.FcmService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class FcmServiceTest {

    @Test
    @DisplayName("FCM Mock: Silent sync and rich resurfacing push notifications succeed")
    void testFcmMockDelivery() {
        FcmService fcmService = new FcmService();
        ReflectionTestUtils.setField(fcmService, "mockEnabled", true);

        UUID captureId = UUID.randomUUID();

        // 1. Silent sync push
        boolean silentDelivered = fcmService.sendSilentSyncNotification("mock-fcm-token-123", captureId);
        assertTrue(silentDelivered);

        // 2. Rich resurfacing alert
        boolean richDelivered = fcmService.sendRichResurfacingNotification(
                "mock-fcm-token-123",
                "Latyr Recall",
                "Ready to watch Dark?",
                captureId,
                Map.of("category", "Entertainment")
        );
        assertTrue(richDelivered);

        // 3. Null token should return false gracefully
        assertFalse(fcmService.sendSilentSyncNotification(null, captureId));
        assertFalse(fcmService.sendRichResurfacingNotification("", "Title", "Body", captureId, null));
    }
}
