package com.latyr.api;

import com.latyr.api.config.AsyncConfig;
import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.service.DurableIngestionStore;
import com.latyr.api.service.IngestionPipelineService;
import com.latyr.api.worker.IngestionQueueWorker;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Executor;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class IngestionQueueWorkerTest {
    private final DurableIngestionStore store = mock(DurableIngestionStore.class);
    private final IngestionPipelineService pipeline = mock(IngestionPipelineService.class);
    private final ScheduledExecutorService heartbeat = mock(ScheduledExecutorService.class);

    @Test
    void capacityIsReservedBeforeClaimAndReleasedAfterExecution() {
        List<Runnable> queue = new ArrayList<>();
        IngestionJob first = job();
        IngestionJob second = job();
        when(store.claim(anyString(), eq(120))).thenReturn(Optional.of(first), Optional.of(second), Optional.empty());
        var worker = worker(queue::add, 2);
        worker.pollAndProcessJobs();
        worker.pollAndProcessJobs();
        verify(store, times(2)).claim(anyString(), eq(120));
        assertEquals(2, queue.size());
        queue.getFirst().run();
        worker.pollAndProcessJobs();
        verify(store, times(3)).claim(anyString(), eq(120));
        verify(pipeline).processJob(first);
    }

    @Test
    void rejectedSubmissionReturnsOwnershipAndCapacity() {
        IngestionJob claimed = job();
        when(store.claim(anyString(), eq(120))).thenReturn(Optional.of(claimed), Optional.empty());
        Executor rejecting = task -> { throw new RejectedExecutionException(); };
        var worker = worker(rejecting, 1);
        worker.pollAndProcessJobs();
        verify(store).releaseClaim(claimed);
        worker.pollAndProcessJobs();
        verify(store, times(2)).claim(anyString(), eq(120));
        verifyNoInteractions(pipeline);
    }

    @Test
    void claimFailureDoesNotLeakCapacity() {
        when(store.claim(anyString(), eq(120))).thenThrow(new IllegalStateException()).thenReturn(Optional.empty());
        var worker = worker(Runnable::run, 1);
        worker.pollAndProcessJobs();
        worker.pollAndProcessJobs();
        verify(store, times(2)).claim(anyString(), eq(120));
    }

    @Test
    void heartbeatRejectionReturnsUnusedClaimWithoutChargingAnAttempt() {
        IngestionJob claimed = job();
        when(store.claim(anyString(), eq(120))).thenReturn(Optional.of(claimed), Optional.empty());
        doThrow(new RejectedExecutionException()).when(heartbeat)
                .scheduleWithFixedDelay(any(Runnable.class), eq(30L), eq(30L), eq(TimeUnit.SECONDS));
        var worker = worker(Runnable::run, 1);
        worker.pollAndProcessJobs();
        verify(store).releaseClaim(claimed);
        verifyNoInteractions(pipeline);
        worker.pollAndProcessJobs();
        verify(store, times(2)).claim(anyString(), eq(120));
    }

    @Test
    void heartbeatRenewsWhileRunningAndIsCancelledOnExit() {
        IngestionJob claimed = job();
        when(store.claim(anyString(), eq(120))).thenReturn(Optional.of(claimed));
        ScheduledFuture<?> renewal = mock(ScheduledFuture.class);
        doReturn(renewal).when(heartbeat).scheduleWithFixedDelay(any(Runnable.class), eq(30L), eq(30L), eq(TimeUnit.SECONDS));
        doAnswer(call -> {
            var tick = ArgumentCaptor.forClass(Runnable.class);
            verify(heartbeat).scheduleWithFixedDelay(tick.capture(), eq(30L), eq(30L), eq(TimeUnit.SECONDS));
            when(store.renew(claimed, 120)).thenReturn(true);
            tick.getValue().run();
            verify(store).renew(claimed, 120);
            return null;
        }).when(pipeline).processJob(claimed);
        worker(Runnable::run, 1).pollAndProcessJobs();
        verify(renewal).cancel(false);
    }

    @Test
    void losingLeaseInterruptsTheRunnerAndStillCancelsRenewal() {
        IngestionJob claimed = job();
        when(store.claim(anyString(), eq(120))).thenReturn(Optional.of(claimed));
        ScheduledFuture<?> renewal = mock(ScheduledFuture.class);
        doReturn(renewal).when(heartbeat).scheduleWithFixedDelay(any(Runnable.class), eq(30L), eq(30L), eq(TimeUnit.SECONDS));
        doAnswer(call -> {
            var tick = ArgumentCaptor.forClass(Runnable.class);
            verify(heartbeat).scheduleWithFixedDelay(tick.capture(), eq(30L), eq(30L), eq(TimeUnit.SECONDS));
            when(store.renew(claimed, 120)).thenReturn(false);
            try {
                tick.getValue().run();
                assertTrue(Thread.interrupted());
            } finally {
                Thread.interrupted();
            }
            return null;
        }).when(pipeline).processJob(claimed);
        worker(Runnable::run, 1).pollAndProcessJobs();
        verify(renewal).cancel(false);
    }

    @Test
    void unexpectedRunnerFailureLeavesLeaseRecoveryAndReleasesCapacity() {
        IngestionJob claimed = job();
        when(store.claim(anyString(), eq(120))).thenReturn(Optional.of(claimed), Optional.empty());
        doThrow(new IllegalStateException("private provider details")).when(pipeline).processJob(claimed);
        var worker = worker(Runnable::run, 1);
        worker.pollAndProcessJobs();
        verify(store, never()).retryOrFail(any(), anyBoolean(), anyString());
        verify(store, never()).releaseClaim(claimed);
        worker.pollAndProcessJobs();
        verify(store, times(2)).claim(anyString(), eq(120));
    }

    @Test
    void invalidCapacityAndLeaseConfigurationFailAtStartup() {
        assertThrows(IllegalArgumentException.class, () -> worker(Runnable::run, 0));
        assertThrows(IllegalArgumentException.class,
                () -> new IngestionQueueWorker(store, pipeline, Runnable::run, heartbeat, 1, 60, 30));
    }

    @Test
    void executionActuallyUsesJava21VirtualThreads() throws Exception {
        try (var executor = new AsyncConfig().virtualThreadExecutor()) {
            assertTrue(executor.submit(() -> Thread.currentThread().isVirtual()).get());
        }
    }

    private IngestionQueueWorker worker(Executor executor, int capacity) {
        return new IngestionQueueWorker(store, pipeline, executor, heartbeat, capacity, 120, 30);
    }

    private static IngestionJob job() {
        var job = new IngestionJob();
        job.setId(UUID.randomUUID());
        return job;
    }
}
