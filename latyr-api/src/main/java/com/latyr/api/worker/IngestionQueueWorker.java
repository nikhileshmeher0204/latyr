package com.latyr.api.worker;

import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.service.DurableIngestionStore;
import com.latyr.api.service.IngestionPipelineService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Executor;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

@Component
public class IngestionQueueWorker {
    private static final Logger log = LoggerFactory.getLogger(IngestionQueueWorker.class);
    private final String workerInstanceId = "worker-" + UUID.randomUUID();
    private final DurableIngestionStore store;
    private final IngestionPipelineService pipeline;
    private final Executor executor;
    private final ScheduledExecutorService heartbeat;
    private final Semaphore capacity;
    private final int maxConcurrent;
    private final int leaseSeconds;
    private final int heartbeatSeconds;

    public IngestionQueueWorker(
            DurableIngestionStore store,
            IngestionPipelineService pipeline,
            @Qualifier("virtualThreadExecutor") Executor executor,
            @Qualifier("ingestionLeaseHeartbeat") ScheduledExecutorService heartbeat,
            @Value("${latyr.queue.max-concurrent:4}") int maxConcurrent,
            @Value("${latyr.queue.lease-seconds:120}") int leaseSeconds,
            @Value("${latyr.queue.heartbeat-seconds:30}") int heartbeatSeconds) {
        if (maxConcurrent < 1 || leaseSeconds < 3 || heartbeatSeconds < 1
                || (long) heartbeatSeconds * 2 >= leaseSeconds) {
            throw new IllegalArgumentException("Queue capacity and lease heartbeat configuration is invalid");
        }
        this.store = store;
        this.pipeline = pipeline;
        this.executor = executor;
        this.heartbeat = heartbeat;
        this.capacity = new Semaphore(maxConcurrent);
        this.maxConcurrent = maxConcurrent;
        this.leaseSeconds = leaseSeconds;
        this.heartbeatSeconds = heartbeatSeconds;
    }

    @Scheduled(fixedDelayString = "${latyr.queue.poll-interval-ms:2000}")
    public void pollAndProcessJobs() {
        // Reserve local execution capacity before acquiring durable ownership.
        for (int dispatched = 0; dispatched < maxConcurrent && capacity.tryAcquire(); dispatched++) {
            IngestionJob claimed = null;
            try {
                Optional<IngestionJob> next = store.claim(workerInstanceId, leaseSeconds);
                if (next.isEmpty()) {
                    capacity.release();
                    break;
                }
                claimed = next.get();
                IngestionJob job = claimed;
                executor.execute(() -> processClaim(job));
            } catch (RuntimeException failure) {
                capacity.release();
                if (claimed != null) {
                    try {
                        store.releaseClaim(claimed);
                    } catch (RuntimeException ignored) {
                        // The durable lease expires if the database is unavailable.
                        log.warn("Could not release rejected claim {}", claimed.getId());
                    }
                }
                log.warn("Queue dispatch failed ({})", failure.getClass().getSimpleName());
                break;
            }
        }
    }

    private void processClaim(IngestionJob job) {
        ScheduledFuture<?> renewal = null;
        boolean processingStarted = false;
        Thread runner = Thread.currentThread();
        try {
            renewal = heartbeat.scheduleWithFixedDelay(() -> {
                try {
                    if (!store.renew(job, leaseSeconds)) {
                        runner.interrupt();
                    }
                } catch (RuntimeException failure) {
                    // Fenced persistence refuses any write once the lease expires.
                    log.warn("Lease renewal failed for job {} ({})", job.getId(), failure.getClass().getSimpleName());
                }
            }, heartbeatSeconds, heartbeatSeconds, TimeUnit.SECONDS);
            processingStarted = true;
            pipeline.processJob(job);
        } catch (RuntimeException failure) {
            if (!processingStarted) {
                try {
                    store.releaseClaim(job);
                } catch (RuntimeException ignored) {
                    log.warn("Unused claim recovery deferred to lease expiry for job {}", job.getId());
                }
            }
            // A failed finalization must recover capture, quota and events together.
            log.warn("Job execution recovery deferred to lease expiry for {}", job.getId());
        } finally {
            if (renewal != null) {
                renewal.cancel(false);
            }
            capacity.release();
        }
    }
}
