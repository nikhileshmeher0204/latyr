package com.latyr.api.worker;

import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.mapper.IngestionJobMapper;
import com.latyr.api.service.IngestionPipelineService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Executor;

@Component
public class IngestionQueueWorker {

    private static final Logger log = LoggerFactory.getLogger(IngestionQueueWorker.class);
    private final String workerInstanceId = "worker-" + UUID.randomUUID().toString().substring(0, 8);

    private final IngestionJobMapper ingestionJobMapper;
    private final IngestionPipelineService pipelineService;
    private final Executor virtualThreadExecutor;

    public IngestionQueueWorker(
            IngestionJobMapper ingestionJobMapper,
            IngestionPipelineService pipelineService,
            @Qualifier("virtualThreadExecutor") Executor virtualThreadExecutor) {
        this.ingestionJobMapper = ingestionJobMapper;
        this.pipelineService = pipelineService;
        this.virtualThreadExecutor = virtualThreadExecutor;
        log.info("Initialized IngestionQueueWorker with instance ID: {}", workerInstanceId);
    }

    /**
     * Immediate async trigger dispatched directly from capture creation.
     */
    public void triggerAsync(IngestionJob job) {
        virtualThreadExecutor.execute(() -> {
            try {
                pipelineService.processJob(job);
            } catch (Exception e) {
                log.error("Unhandled error in immediate async trigger for job {}: {}", job.getId(), e.getMessage(), e);
            }
        });
    }

    /**
     * Transactional polling sweeper executing SELECT ... FOR UPDATE SKIP LOCKED.
     * Polls to claim unhandled or retried jobs across distributed workers.
     */
    @Scheduled(fixedDelayString = "${latyr.queue.poll-interval-ms:2000}")
    public void pollAndProcessJobs() {
        try {
            Optional<IngestionJob> jobOpt = ingestionJobMapper.lockNextPendingJob(workerInstanceId);
            while (jobOpt.isPresent()) {
                IngestionJob job = jobOpt.get();
                log.debug("Worker {} claimed job {}", workerInstanceId, job.getId());

                virtualThreadExecutor.execute(() -> pipelineService.processJob(job));

                // Claim next pending job in current tick
                jobOpt = ingestionJobMapper.lockNextPendingJob(workerInstanceId);
            }
        } catch (Exception e) {
            log.warn("Error during queue polling tick: {}", e.getMessage());
        }
    }

    /**
     * Sweeps zombie/stale locks (e.g. from crashed containers) every 5 minutes.
     * Resets PROCESSING jobs older than 10 minutes back to PENDING.
     */
    @Scheduled(fixedDelay = 300000)
    public void sweepStaleLocks() {
        try {
            int resetCount = ingestionJobMapper.resetStaleLocks(10);
            if (resetCount > 0) {
                log.warn("Swept and reset {} stale ingestion job locks", resetCount);
            }
        } catch (Exception e) {
            log.error("Failed to sweep stale job locks: {}", e.getMessage());
        }
    }
}
