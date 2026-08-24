package com.latyr.api;

import com.latyr.api.service.FcmService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class FcmServiceTest {

    @Test
    @DisplayName("FCM Graceful handling: Null or empty token returns false gracefully")
    void testFcmNullTokenHandling() {
        FcmService fcmService = new FcmService();
        UUID captureId = UUID.randomUUID();

        assertFalse(fcmService.sendSilentSyncNotification(null, captureId));
        assertFalse(fcmService.sendSilentSyncNotification("", captureId));
        assertFalse(fcmService.sendRichResurfacingNotification(null, "Title", "Body", captureId, null));
        assertFalse(fcmService.sendRichResurfacingNotification("", "Title", "Body", captureId, null));
    }
}
