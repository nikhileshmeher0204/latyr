package com.latyr.api;

import com.latyr.api.service.SseNotificationService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class SseNotificationServiceTest {

    @Test
    @DisplayName("SSE Stream: Should subscribe user and deliver broadcast event safely")
    void testSubscribeAndEmit() {
        SseNotificationService service = new SseNotificationService();
        UUID userId = UUID.randomUUID();

        SseEmitter emitter = service.subscribe(userId);
        assertNotNull(emitter);

        // Should not throw when emitting to active subscriber
        assertDoesNotThrow(() -> {
            service.emitCaptureEvent(userId, "CAPTURE_COMPLETED", Map.of("capture_id", UUID.randomUUID(), "status", "COMPLETED"));
        });

        // Heartbeat should execute cleanly
        assertDoesNotThrow(service::sendHeartbeat);
    }
}
