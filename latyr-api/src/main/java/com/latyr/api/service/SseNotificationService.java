package com.latyr.api.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class SseNotificationService {

    private static final Logger log = LoggerFactory.getLogger(SseNotificationService.class);
    private static final long SSE_TIMEOUT_MS = 30 * 60 * 1000L; // 30 minutes

    private final Map<UUID, List<SseEmitter>> userEmitters = new ConcurrentHashMap<>();

    public SseEmitter subscribe(UUID userId) {
        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);

        userEmitters.computeIfAbsent(userId, k -> new CopyOnWriteArrayList<>()).add(emitter);
        log.info("User {} subscribed to real-time SSE stream. Active emitters: {}", userId, userEmitters.get(userId).size());

        emitter.onCompletion(() -> removeEmitter(userId, emitter));
        emitter.onTimeout(() -> removeEmitter(userId, emitter));
        emitter.onError(e -> removeEmitter(userId, emitter));

        try {
            // Send initial connection event
            emitter.send(SseEmitter.event()
                    .name("CONNECTED")
                    .data(Map.of("message", "Connected to Latyr real-time notification stream", "timestamp", System.currentTimeMillis())));
        } catch (IOException e) {
            removeEmitter(userId, emitter);
        }

        return emitter;
    }

    public void emitCaptureEvent(UUID userId, String eventType, Object payload) {
        List<SseEmitter> emitters = userEmitters.get(userId);
        if (emitters == null || emitters.isEmpty()) {
            log.debug("No active SSE connections for user {}", userId);
            return;
        }

        log.info("Emitting SSE event '{}' to {} client(s) for user {}", eventType, emitters.size(), userId);
        List<SseEmitter> failedEmitters = new ArrayList<>();

        for (SseEmitter emitter : emitters) {
            try {
                emitter.send(SseEmitter.event()
                        .name(eventType)
                        .data(payload));
            } catch (Exception e) {
                log.warn("Failed to deliver SSE event to client for user {}: {}", userId, e.getMessage());
                failedEmitters.add(emitter);
            }
        }

        emitters.removeAll(failedEmitters);
    }

    /**
     * Heartbeat ping every 25 seconds to keep proxies / firewalls from dropping the SSE socket.
     */
    @Scheduled(fixedDelay = 25000)
    public void sendHeartbeat() {
        if (userEmitters.isEmpty()) return;

        for (Map.Entry<UUID, List<SseEmitter>> entry : userEmitters.entrySet()) {
            UUID userId = entry.getKey();
            List<SseEmitter> emitters = entry.getValue();
            List<SseEmitter> failed = new ArrayList<>();

            for (SseEmitter emitter : emitters) {
                try {
                    emitter.send(SseEmitter.event().comment("ping"));
                } catch (Exception e) {
                    failed.add(emitter);
                }
            }
            emitters.removeAll(failed);
            if (emitters.isEmpty()) {
                userEmitters.remove(userId);
            }
        }
    }

    private void removeEmitter(UUID userId, SseEmitter emitter) {
        List<SseEmitter> emitters = userEmitters.get(userId);
        if (emitters != null) {
            emitters.remove(emitter);
            if (emitters.isEmpty()) {
                userEmitters.remove(userId);
            }
            log.debug("Removed SSE emitter for user {}", userId);
        }
    }
}
