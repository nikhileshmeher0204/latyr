package com.latyr.api.worker;

import com.latyr.api.mapper.IngestionOutboxMapper;
import com.latyr.api.service.SseNotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class IngestionOutboxWorker {
    private static final Logger log = LoggerFactory.getLogger(IngestionOutboxWorker.class);
    private final IngestionOutboxMapper mapper;
    private final SseNotificationService sse;

    public IngestionOutboxWorker(IngestionOutboxMapper mapper, SseNotificationService sse) {
        this.mapper = mapper;
        this.sse = sse;
    }

    @Scheduled(fixedDelayString="${latyr.queue.event-poll-interval-ms:2000}")
    public void dispatch() {
        for (int i = 0; i < 32; i++) {
            var next = mapper.claim();
            if (next.isEmpty()) return;
            var event = next.get();
            if (event.getAttemptCount() > 10) continue;
            try {
                // SSE is a live hint; disconnected clients recover current state from the feed.
                sse.emitOutboxEvent(event.getUserId(), event.getEventType(), event.getPayload());
                mapper.delivered(event);
            } catch (Exception failure) {
                mapper.retry(event);
                log.warn("Ingestion event {} delivery failed on attempt {}", event.getId(), event.getAttemptCount());
            }
        }
    }
}
