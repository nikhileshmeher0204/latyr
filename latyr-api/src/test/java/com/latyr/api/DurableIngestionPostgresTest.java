package com.latyr.api;

import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.domain.model.ExtractedEntity;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.exception.AnalysisOutcomeUnknownException;
import com.latyr.api.exception.IngestionLeaseLostException;
import com.latyr.api.mapper.IngestionJobMapper;
import com.latyr.api.mapper.ExtractedEntityMapper;
import com.latyr.api.mapper.IngestionOutboxMapper;
import com.latyr.api.mapper.IngestionStageMapper;
import com.latyr.api.service.DurableIngestionStore;
import com.latyr.api.service.IngestionEventOutbox;
import com.latyr.api.service.SseNotificationService;
import com.latyr.api.support.PostgresTestDatabase;
import com.latyr.api.worker.IngestionOutboxWorker;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@EnabledIfEnvironmentVariable(named="TEST_DATABASE_URL", matches=".+")
class DurableIngestionPostgresTest {
    private PostgresTestDatabase db;
    private DurableIngestionStore store;
    private IngestionOutboxMapper outboxMapper;
    private IngestionEventOutbox outbox;

    @BeforeEach
    void setUp() throws Exception {
        db = new PostgresTestDatabase();
        store = new DurableIngestionStore(db.mapper(IngestionJobMapper.class), db.mapper(IngestionStageMapper.class), db.manager());
        outboxMapper = db.mapper(IngestionOutboxMapper.class);
        outbox = new IngestionEventOutbox(outboxMapper);
    }

    @AfterEach
    void close() { if (db != null) db.close(); }

    @Test
    void concurrentPollersClaimOneJobAndIncrementAttemptOnce() throws Exception {
        seed(null);
        try (var executor = Executors.newFixedThreadPool(8)) {
            List<Callable<Optional<IngestionJob>>> calls = new ArrayList<>();
            for (int i = 0; i < 16; i++) calls.add(() -> store.claim("worker", 60));
            int claimed = 0;
            for (var result : executor.invokeAll(calls)) if (result.get(10, TimeUnit.SECONDS).isPresent()) claimed++;
            assertEquals(1, claimed);
        }
        assertEquals(1, db.jdbc().queryForObject("SELECT attempt_count FROM ingestion_jobs", Integer.class));
    }

    @Test
    void sourceLeaseSerializesDifferentUsersCapturingSameSource() throws Exception {
        var first = seed(null);
        seed(first.sourceId());
        try (var executor = Executors.newFixedThreadPool(2)) {
            var calls = List.<Callable<Optional<IngestionJob>>>of(() -> store.claim("a",60), () -> store.claim("b",60));
            int count = 0;
            for (var result : executor.invokeAll(calls)) if (result.get(10,TimeUnit.SECONDS).isPresent()) count++;
            assertEquals(1, count);
        }
        assertEquals(1, db.jdbc().queryForObject("SELECT count(*) FROM ingestion_jobs WHERE status='PROCESSING'", Integer.class));
    }

    @Test
    void uncommittedAdmissionIsInvisibleAndRollbackLeavesNoRunnableJob() throws Exception {
        var fixture = seed(null);
        db.jdbc().update("DELETE FROM ingestion_jobs WHERE id=?", fixture.jobId());
        try (var executor = Executors.newSingleThreadExecutor()) {
            db.transactions().executeWithoutResult(transaction -> {
                insertJob(fixture.jobId(), fixture.captureId(), fixture.userId(), fixture.sourceId());
                try {
                    assertTrue(executor.submit(() -> store.claim("other",60)).get(5,TimeUnit.SECONDS).isEmpty());
                } catch (Exception failure) { throw new RuntimeException(failure); }
                transaction.setRollbackOnly();
            });
        }
        assertTrue(store.claim("after-rollback",60).isEmpty());
    }

    @Test
    void expiredWorkerCannotChangeCaptureCheckpointOrReplacementState() {
        var fixture = seed(null);
        var old = store.claim("old",60).orElseThrow();
        expire(old);
        var replacement = store.claim("new",60).orElseThrow();
        assertNotEquals(old.getLeaseToken(), replacement.getLeaseToken());
        assertEquals(2,replacement.getAttemptCount());
        assertThrows(IngestionLeaseLostException.class, () -> store.withLease(old,
            () -> db.jdbc().update("UPDATE captures SET title='stale' WHERE id=?",fixture.captureId())));
        assertThrows(IngestionLeaseLostException.class, () -> store.complete(old));
        assertThrows(IngestionLeaseLostException.class, () -> store.retryOrFail(old,false,"FAILED"));
        assertFalse(store.renew(old,60));
        assertNull(db.jdbc().queryForObject("SELECT title FROM captures WHERE id=?",String.class,fixture.captureId()));
        store.withLease(replacement, () -> db.jdbc().update("UPDATE captures SET title='current' WHERE id=?",fixture.captureId()));
        assertEquals("current",db.jdbc().queryForObject("SELECT title FROM captures WHERE id=?",String.class,fixture.captureId()));
    }

    @Test
    void checkpointsSurviveRetryAndCompletedAnalysisCannotBeOverwritten() {
        seed(null);
        var first = store.claim("first",60).orElseThrow();
        store.startStage(first,"ANALYSIS");
        store.completeStage(first,"ANALYSIS",Map.of("entities",List.of(Map.of("title","Source-grounded intent"))));
        assertFalse(store.retryOrFail(first,true,"ENRICHMENT_UNAVAILABLE"));
        assertTrue(store.claim("too-soon",60).isEmpty());
        db.jdbc().update("UPDATE ingestion_jobs SET next_attempt_at=clock_timestamp()-INTERVAL '1 second'");
        var retry = store.claim("retry",60).orElseThrow();
        assertNotNull(store.loadCheckpoint(retry,"ANALYSIS"));
        assertThrows(IllegalStateException.class, () -> store.startStage(retry,"ANALYSIS"));
        assertEquals(1,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_stage_attempts",Integer.class));
    }

    @Test
    void crashDuringAnalysisRecordsAmbiguityAndNeverReplaysAnalysis() {
        seed(null);
        var old = store.claim("old",60).orElseThrow();
        store.startStage(old,"ANALYSIS");
        expire(old);
        var replacement = store.claim("replacement",60).orElseThrow();
        assertThrows(AnalysisOutcomeUnknownException.class, () -> store.startStage(replacement,"ANALYSIS"));
        assertEquals("AMBIGUOUS",db.jdbc().queryForObject("SELECT status FROM ingestion_stage_attempts",String.class));
        assertEquals("AMBIGUOUS",db.jdbc().queryForObject("SELECT status FROM ingestion_stage_checkpoints",String.class));
    }

    @Test
    void unknownProviderOutcomePreventsAnotherUsersAnalysisReplay() {
        var fixture = seed(null);
        var first = store.claim("first",60).orElseThrow();
        store.startStage(first,"ANALYSIS");
        store.failStage(first,"ANALYSIS","AI_OUTCOME_UNKNOWN");
        store.retryOrFail(first,false,"AI_OUTCOME_UNKNOWN");
        seed(fixture.sourceId());
        var nextUser = store.claim("next",60).orElseThrow();
        assertThrows(AnalysisOutcomeUnknownException.class, () -> store.startStage(nextUser,"ANALYSIS"));
    }

    @Test
    void failedSourceCanRetryAndExecutorRejectionDoesNotConsumeAttempt() {
        seed(null);
        var rejected = store.claim("rejected",60).orElseThrow();
        store.releaseClaim(rejected);
        var first = store.claim("first",60).orElseThrow();
        assertEquals(1,first.getAttemptCount());
        store.startStage(first,"SOURCE");
        store.failStage(first,"SOURCE","SOURCE_UNAVAILABLE");
        assertFalse(store.retryOrFail(first,true,"SOURCE_UNAVAILABLE"));
        assertTrue(store.claim("early",60).isEmpty());
        db.jdbc().update("UPDATE ingestion_jobs SET next_attempt_at=clock_timestamp()-INTERVAL '1 second'");
        var second = store.claim("second",60).orElseThrow();
        store.startStage(second,"SOURCE");
        store.completeStage(second,"SOURCE",Map.of("caption","Extracted caption"));
        assertEquals(2,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_stage_attempts",Integer.class));
    }

    @Test
    void mediaCanBeDownloadedAgainAfterKnownAnalysisRejectionWithoutRepeatingSource() {
        seed(null);
        var first = store.claim("first",60).orElseThrow();
        store.startStage(first,"SOURCE");
        store.completeStage(first,"SOURCE",Map.of("caption","Source caption"));
        store.startStage(first,"MEDIA");
        store.completeStage(first,"MEDIA",Map.of("byte_count",128));
        store.startStage(first,"ANALYSIS");
        store.failStage(first,"ANALYSIS","RATE_LIMITED");
        store.retryOrFail(first,true,"RATE_LIMITED");
        db.jdbc().update("UPDATE ingestion_jobs SET next_attempt_at=clock_timestamp()-INTERVAL '1 second'");
        var retry = store.claim("retry",60).orElseThrow();
        assertNotNull(store.loadCheckpoint(retry,"SOURCE"));
        store.startStage(retry,"MEDIA");
        store.completeStage(retry,"MEDIA",Map.of("byte_count",128));
        store.startStage(retry,"ANALYSIS");
        store.completeStage(retry,"ANALYSIS",Map.of("entities",List.of(Map.of("title","Useful intent"))));
        assertEquals(1,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_stage_attempts WHERE stage='SOURCE'",Integer.class));
        assertEquals(2,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_stage_attempts WHERE stage='MEDIA'",Integer.class));
        assertEquals(2,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_stage_attempts WHERE stage='ANALYSIS'",Integer.class));
    }

    @Test
    void crashAttemptsAreBoundedAndExhaustedLeaseRemainsRecoverableForTerminalAccounting() {
        seed(null);
        db.jdbc().update("UPDATE ingestion_jobs SET max_attempts=1");
        var first = store.claim("first",60).orElseThrow();
        expire(first);
        var recovery = store.claim("recovery",60).orElseThrow();
        assertTrue(recovery.getAttemptCount()>recovery.getMaxAttempts());
        assertTrue(store.retryOrFail(recovery,true,"ATTEMPTS_EXHAUSTED"));
        assertTrue(store.claim("later",60).isEmpty());
        assertEquals("FAILED",db.jdbc().queryForObject("SELECT status FROM ingestion_jobs",String.class));
    }

    @Test
    void outboxCrashRecoveryStopsAfterBoundedDeliveryAttempts() {
        var fixture = seed(null);
        db.transactions().executeWithoutResult(tx -> outbox.append(fixture.userId(),"CAPTURE_PROCESSING",Map.of("capture_id",fixture.captureId())));
        db.jdbc().update("UPDATE ingestion_event_outbox SET status='DELIVERING',attempt_count=10,lease_expires_at=clock_timestamp()-INTERVAL '1 second'");
        var sse = mock(SseNotificationService.class);
        new IngestionOutboxWorker(outboxMapper,sse).dispatch();
        verifyNoInteractions(sse);
        assertEquals("FAILED",db.jdbc().queryForObject("SELECT status FROM ingestion_event_outbox",String.class));
        assertTrue(outboxMapper.claim().isEmpty());
    }

    @Test
    void finalizationRollbackRemovesPartialCaptureWritesAndOutboxEvent() {
        var fixture = seed(null);
        var job = store.claim("worker",60).orElseThrow();
        assertThrows(IllegalStateException.class, () -> store.withLease(job, () -> {
            db.jdbc().update("UPDATE captures SET status='COMPLETED',title='rollback' WHERE id=?",fixture.captureId());
            outbox.append(fixture.userId(),"CAPTURE_COMPLETED",Map.of("capture_id",fixture.captureId()));
            store.complete(job);
            throw new IllegalStateException("injected finalization failure");
        }));
        assertEquals("PENDING",db.jdbc().queryForObject("SELECT status FROM captures",String.class));
        assertEquals("PROCESSING",db.jdbc().queryForObject("SELECT status FROM ingestion_jobs",String.class));
        assertEquals(0,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_event_outbox",Integer.class));
    }

    @Test
    void completedStateAndEventCommitTogetherAndDeliveryRetryDoesNotChangeAnalysis() throws Exception {
        var fixture = seed(null);
        var job = store.claim("worker",60).orElseThrow();
        store.startStage(job,"ANALYSIS");
        store.completeStage(job,"ANALYSIS",Map.of("entities",List.of(Map.of("title","Useful intent"))));
        try (var executor = Executors.newSingleThreadExecutor()) {
            store.withLease(job, () -> {
                db.jdbc().update("UPDATE captures SET status='COMPLETED' WHERE id=?",fixture.captureId());
                outbox.append(fixture.userId(),"CAPTURE_COMPLETED",Map.of("capture_id",fixture.captureId(),"created_at",Instant.now()));
                try { assertTrue(executor.submit(() -> outboxMapper.claim()).get(5,TimeUnit.SECONDS).isEmpty()); }
                catch (Exception failure) { throw new RuntimeException(failure); }
                store.complete(job);
            });
        }
        var sse = mock(SseNotificationService.class);
        doThrow(new IllegalStateException("delivery failed")).when(sse).emitOutboxEvent(any(),any(),any());
        new IngestionOutboxWorker(outboxMapper,sse).dispatch();
        assertEquals("PENDING",db.jdbc().queryForObject("SELECT status FROM ingestion_event_outbox",String.class));
        assertEquals("COMPLETED",db.jdbc().queryForObject("SELECT status FROM ingestion_jobs",String.class));
        assertEquals("COMPLETED",db.jdbc().queryForObject("SELECT status FROM ingestion_stage_checkpoints",String.class));
        db.jdbc().update("UPDATE ingestion_event_outbox SET next_attempt_at=clock_timestamp()-INTERVAL '1 second'");
        reset(sse);
        new IngestionOutboxWorker(outboxMapper,sse).dispatch();
        assertEquals("DELIVERED",db.jdbc().queryForObject("SELECT status FROM ingestion_event_outbox",String.class));
        assertEquals(1,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_stage_attempts",Integer.class));
    }

    @Test
    void staleOutboxDispatcherCannotAcknowledgeReplacementLease() {
        var fixture = seed(null);
        db.transactions().executeWithoutResult(tx -> outbox.append(fixture.userId(),"CAPTURE_PROCESSING",Map.of("capture_id",fixture.captureId())));
        var old = outboxMapper.claim().orElseThrow();
        db.jdbc().update("UPDATE ingestion_event_outbox SET lease_expires_at=clock_timestamp()-INTERVAL '1 second'");
        var current = outboxMapper.claim().orElseThrow();
        assertNotEquals(old.getLeaseToken(),current.getLeaseToken());
        assertEquals(0,outboxMapper.delivered(old));
        assertEquals(0,outboxMapper.retry(old));
        assertEquals(1,outboxMapper.delivered(current));
    }

    @Test
    void persistedExtractionOrderSurvivesEqualCreationTimesAndReverseIds() {
        var fixture = seed(null);
        var mapper = db.mapper(ExtractedEntityMapper.class);
        for (int index = 0; index < 3; index++) {
            var entity = new ExtractedEntity(fixture.captureId(),EntityType.IDEA,"Intent " + index);
            entity.setId(UUID.fromString("00000000-0000-0000-0000-00000000000" + (3-index)));
            entity.setActionCta(ActionCTA.REMEMBER);
            entity.setExtractionIndex(index);
            entity.setCreatedAt(Instant.parse("2026-10-01T00:00:00Z"));
            mapper.insert(entity);
        }
        var rows = mapper.findByCaptureId(fixture.captureId());
        assertEquals(List.of("Intent 0","Intent 1","Intent 2"),rows.stream().map(ExtractedEntity::getTitle).toList());
        assertEquals(List.of(0,1,2),rows.stream().map(ExtractedEntity::getExtractionIndex).toList());
    }

    @Test
    void sourceOwnedAmbiguityAndSuccessfulCheckpointSurviveInitiatingAccountDeletion() {
        for (boolean ambiguous : List.of(true,false)) {
            var first = seed(null);
            var firstJob = store.claim("first",60).orElseThrow();
            store.startStage(firstJob,"ANALYSIS");
            if (ambiguous) store.failStage(firstJob,"ANALYSIS","AI_OUTCOME_UNKNOWN");
            else store.completeStage(firstJob,"ANALYSIS",Map.of("entities",List.of(Map.of("title","Public intent"))));
            // The active source lease is also safely released through its job FK becoming null.
            db.jdbc().update("DELETE FROM users WHERE id=?",first.userId());
            assertEquals(1,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_stage_checkpoints WHERE canonical_source_id=?",Integer.class,first.sourceId()));
            seed(first.sourceId());
            var next = store.claim("next-user",60).orElseThrow();
            if (ambiguous) assertThrows(AnalysisOutcomeUnknownException.class, () -> store.startStage(next,"ANALYSIS"));
            else assertNotNull(store.loadCheckpoint(next,"ANALYSIS"));
            store.complete(next);
        }
    }

    private void expire(IngestionJob job) {
        db.jdbc().update("UPDATE ingestion_jobs SET lease_expires_at=clock_timestamp()-INTERVAL '1 second' WHERE id=?",job.getId());
        db.jdbc().update("UPDATE canonical_source_leases SET lease_expires_at=clock_timestamp()-INTERVAL '1 second' WHERE canonical_source_id=?",job.getCanonicalSourceId());
    }

    private Fixture seed(UUID existingSource) {
        UUID user = UUID.randomUUID();
        UUID source = existingSource == null ? UUID.randomUUID() : existingSource;
        UUID capture = UUID.randomUUID();
        UUID job = UUID.randomUUID();
        db.jdbc().update("INSERT INTO users(id,firebase_uid,email) VALUES(?,?,?)",user,user.toString(),"test@example.invalid");
        if (existingSource == null) db.jdbc().update("INSERT INTO canonical_sources(id,canonical_url_hash,source_type,original_url) VALUES(?,?,'IMAGE','owner-private-image')",source,source.toString());
        db.jdbc().update("INSERT INTO captures(id,user_id,canonical_source_id,content_type) VALUES(?,?,?,'IMAGE')",capture,user,source);
        insertJob(job,capture,user,source);
        return new Fixture(user,source,capture,job);
    }

    private void insertJob(UUID job, UUID capture, UUID user, UUID source) {
        db.jdbc().update("INSERT INTO ingestion_jobs(id,capture_id,user_id,canonical_source_id,source_type,payload) VALUES(?,?,?,?,'IMAGE','{}')",job,capture,user,source);
    }

    private record Fixture(UUID userId,UUID sourceId,UUID captureId,UUID jobId) {}
}
