package com.latyr.api;

import com.latyr.api.adapter.*;
import com.latyr.api.domain.enums.*;
import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.exception.ProviderOperationException;
import com.latyr.api.mapper.*;
import com.latyr.api.service.*;
import com.latyr.api.support.PostgresTestDatabase;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import java.util.*;
import java.util.concurrent.atomic.AtomicReference;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Controlled adapters with real PostgreSQL/MyBatis/transactions; no real-media E2E claims. */
@EnabledIfEnvironmentVariable(named="TEST_DATABASE_URL", matches=".+")
class IngestionPipelinePostgresTest {
    PostgresTestDatabase db;
    DurableIngestionStore store;
    CaptureQuotaLedger ledger;
    IngestionPipelineService pipeline;
    AIProvider ai;
    ScraperProvider scraper;
    EntityEnrichmentProvider enrichment;

    @BeforeEach void setup() throws Exception {
        db = new PostgresTestDatabase();
        store = spy(new DurableIngestionStore(db.mapper(IngestionJobMapper.class),db.mapper(IngestionStageMapper.class),db.manager()));
        var subscriptions = new SubscriptionQuotaService(db.mapper(UserSubscriptionMapper.class),db.mapper(UserSubscriptionHistoryMapper.class),db.mapper(UserMapper.class));
        ledger = new CaptureQuotaLedger(db.mapper(CaptureQuotaLedgerMapper.class),subscriptions,db.mapper(UserSubscriptionMapper.class));
        ai = mock(AIProvider.class); scraper = mock(ScraperProvider.class); enrichment = mock(EntityEnrichmentProvider.class);
        var media = mock(EphemeralMediaStreamer.class); var thumbnails = mock(ThumbnailStorage.class);
        when(scraper.extractMedia(any())).thenAnswer(call -> {
            assertFalse(TransactionSynchronizationManager.isActualTransactionActive(),"Scraping must not hold a database transaction");
            return new ScraperProvider.ScrapedMedia(null,null,null,"Grounded creator recommendation",null,17,Map.of());
        });
        when(media.streamMedia(any())).thenReturn(new byte[0]);
        when(ai.analyzeMedia(any(),any(),any(),any())).thenAnswer(call -> {
            assertFalse(TransactionSynchronizationManager.isActualTransactionActive(),"AI must not hold a database transaction");
            return IngestionPipelineServiceTest.analysis(null);
        });
        when(enrichment.enrichEntities(any())).thenAnswer(call -> {
            assertFalse(TransactionSynchronizationManager.isActualTransactionActive(),"Enrichment must not hold a database transaction");
            return call.getArgument(0);
        });
        pipeline = new IngestionPipelineService(store,db.mapper(CaptureMapper.class),db.mapper(CanonicalSourceMapper.class),
            db.mapper(ExtractedEntityMapper.class),scraper,media,ai,enrichment,thumbnails,ledger,
            new IngestionEventOutbox(db.mapper(IngestionOutboxMapper.class)));
    }
    @AfterEach void close() { if(db != null) db.close(); }

    @Test void twoUsersReuseOneSuccessfulAnalysisAndEachFinalizeOneUnit() {
        doAnswer(call -> {
            try { call.callRealMethod(); }
            catch (RuntimeException failure) { throw new AssertionError("Unexpected finalization failure",failure); }
            return null;
        }).when(store).withLease(any(),any());
        var first = seed(null); var second = seed(first.source());
        pipeline.processJob(store.claim("first",60).orElseThrow());
        pipeline.processJob(store.claim("second",60).orElseThrow());
        assertEquals(2,count("captures WHERE status='COMPLETED'"));
        assertEquals(2,count("capture_quota_ledger WHERE state='FINALIZED'"));
        assertEquals(2,db.jdbc().queryForObject("SELECT sum(monthly_capture_count)::int FROM user_subscriptions",Integer.class));
        assertEquals(2,count("extracted_entities"));
        verify(ai,times(1)).analyzeMedia(any(),any(),any(),eq(Language.ORIGINAL));
        verify(scraper,times(1)).extractMedia(any()); verify(enrichment,times(1)).enrichEntities(any());
        assertEquals(2,count("ingestion_event_outbox WHERE event_type='CAPTURE_COMPLETED'"));
    }

    @Test void persistenceFailureRollsBackCoreQuotaAndEventButPreservesPaidAnalysisForRetry() {
        var fixture = seed(null);
        db.jdbc().execute("CREATE FUNCTION reject_test_entity() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'test failure'; END $$");
        db.jdbc().execute("CREATE TRIGGER reject_entity BEFORE INSERT ON extracted_entities FOR EACH ROW EXECUTE FUNCTION reject_test_entity()");
        pipeline.processJob(store.claim("first",60).orElseThrow());
        assertEquals(0,count("captures WHERE status='COMPLETED'"));
        assertEquals(0,count("extracted_entities"));
        assertEquals(0,count("ingestion_event_outbox WHERE event_type='CAPTURE_COMPLETED'"));
        assertEquals(1,count("capture_quota_ledger WHERE state='RESERVED'"));
        assertEquals(0,used(fixture.user()));
        assertEquals(1,count("ingestion_stage_checkpoints WHERE stage='ANALYSIS' AND status='COMPLETED'"));
        assertEquals("PENDING",jobStatus());
        db.jdbc().execute("DROP TRIGGER reject_entity ON extracted_entities");
        due(); pipeline.processJob(store.claim("retry",60).orElseThrow());
        assertEquals(1,count("captures WHERE status='COMPLETED'"));
        assertEquals(1,used(fixture.user()));
        verify(ai,times(1)).analyzeMedia(any(),any(),any(),any());
    }

    @Test void enrichmentRetryKeepsCaptureReadyAndNeverReplaysCoreOrQuota() {
        var fixture = seed(null);
        when(enrichment.enrichEntities(any())).thenAnswer(call -> {
            assertEquals(1,count("captures WHERE status='COMPLETED'")); assertEquals(1,used(fixture.user()));
            throw new ProviderOperationException("ENRICHMENT_UNAVAILABLE",ProviderOperationException.Outcome.RETRYABLE);
        });
        pipeline.processJob(store.claim("first",60).orElseThrow());
        assertEquals("PENDING",jobStatus()); assertEquals(1,used(fixture.user()));
        doAnswer(call -> call.getArgument(0)).when(enrichment).enrichEntities(any());
        due(); pipeline.processJob(store.claim("retry",60).orElseThrow());
        assertEquals("COMPLETED",jobStatus()); assertEquals(1,used(fixture.user()));
        assertEquals(1,count("extracted_entities"));
        assertEquals(1,count("ingestion_event_outbox WHERE event_type='CAPTURE_COMPLETED'"));
        verify(ai,times(1)).analyzeMedia(any(),any(),any(),any());
    }

    @Test void unknownAiOutcomeStaysPartialAndAnotherUserCannotReplayIt() {
        var fixture = seed(null);
        when(ai.analyzeMedia(any(),any(),any(),any())).thenThrow(new RuntimeException("connection lost after request"));
        pipeline.processJob(store.claim("first",60).orElseThrow());
        seed(fixture.source()); pipeline.processJob(store.claim("second",60).orElseThrow());
        assertEquals(2,count("captures WHERE status='PARTIAL'"));
        assertEquals(2,count("capture_quota_ledger WHERE state='RELEASED'"));
        assertEquals(0,count("extracted_entities"));
        verify(ai,times(1)).analyzeMedia(any(),any(),any(),any());
    }

    @Test void knownAiRateLimitRetriesEphemeralMediaButKeepsCompletedSourceCheckpoint() {
        var fixture = seed(null);
        when(ai.analyzeMedia(any(),any(),any(),any()))
            .thenThrow(new ProviderOperationException("AI_RATE_LIMITED",ProviderOperationException.Outcome.RETRYABLE))
            .thenReturn(IngestionPipelineServiceTest.analysis("Recovered"));
        pipeline.processJob(store.claim("first",60).orElseThrow());
        assertEquals("PENDING",jobStatus());
        assertEquals(0,used(fixture.user()));
        assertEquals(1,count("ingestion_stage_checkpoints WHERE stage='MEDIA' AND status='COMPLETED'"));
        assertEquals(1,count("ingestion_stage_checkpoints WHERE stage='ANALYSIS' AND status='FAILED'"));
        due(); pipeline.processJob(store.claim("retry",60).orElseThrow());
        assertEquals("COMPLETED",jobStatus());
        assertEquals(1,count("captures WHERE status='COMPLETED'"));
        assertEquals(1,used(fixture.user()));
        assertEquals(1,count("ingestion_stage_attempts WHERE stage='SOURCE'"));
        assertEquals(2,count("ingestion_stage_attempts WHERE stage='MEDIA'"));
        assertEquals(2,count("ingestion_stage_attempts WHERE stage='ANALYSIS'"));
        verify(scraper,times(1)).extractMedia(any());
        verify(ai,times(2)).analyzeMedia(any(),any(),any(),any());
    }

    @Test void noUsefulIntentsRemainsUnchargedAndCompletedEmptyAnalysisIsNotRerun() {
        var fixture = seed(null);
        when(ai.analyzeMedia(any(),any(),any(),any())).thenReturn(new AIProvider.AIAnalysisResult("Summary","Summary",null,
            Intent.EXPLORE,null,null,null,List.of(),List.of()));
        pipeline.processJob(store.claim("first",60).orElseThrow());
        seed(fixture.source()); pipeline.processJob(store.claim("second",60).orElseThrow());
        assertEquals(2,count("captures WHERE status='PARTIAL'"));
        assertEquals(0,used(fixture.user())); verify(ai,times(1)).analyzeMedia(any(),any(),any(),any());
    }

    @Test void expiredInFlightWorkerCannotPublishLateSuccessAndReplacementDoesNotRerunAi() {
        seed(null); AtomicReference<IngestionJob> replacement = new AtomicReference<>();
        when(ai.analyzeMedia(any(),any(),any(),any())).thenAnswer(call -> {
            db.jdbc().update("UPDATE ingestion_jobs SET lease_expires_at=clock_timestamp()-INTERVAL '1 second'");
            db.jdbc().update("UPDATE canonical_source_leases SET lease_expires_at=clock_timestamp()-INTERVAL '1 second'");
            replacement.set(store.claim("replacement",60).orElseThrow());
            return IngestionPipelineServiceTest.analysis("late");
        });
        pipeline.processJob(store.claim("old",60).orElseThrow());
        assertEquals(0,count("captures WHERE status='COMPLETED'"));
        assertEquals(0,count("extracted_entities"));
        pipeline.processJob(replacement.get());
        assertEquals(1,count("captures WHERE status='PARTIAL'"));
        assertEquals(0,count("ingestion_event_outbox WHERE event_type='CAPTURE_COMPLETED'"));
        verify(ai,times(1)).analyzeMedia(any(),any(),any(),any());
    }

    private Fixture seed(UUID existingSource) {
        UUID user = UUID.randomUUID(), source = existingSource == null ? UUID.randomUUID() : existingSource, capture = UUID.randomUUID();
        db.transactions().executeWithoutResult(tx -> {
            db.jdbc().update("INSERT INTO users(id,firebase_uid,email) VALUES(?,?,?)",user,user.toString(),"fixture@example.invalid");
            if(existingSource == null) db.jdbc().update("INSERT INTO canonical_sources(id,canonical_url_hash,source_type,original_url) VALUES(?,?,'INSTAGRAM_REEL','https://example.test/controlled-fixture')",source,source.toString());
            db.jdbc().update("INSERT INTO captures(id,user_id,canonical_source_id,content_type,source_type) VALUES(?,?,?,'URL','INSTAGRAM_REEL')",capture,user,source);
            db.jdbc().update("INSERT INTO ingestion_jobs(id,capture_id,user_id,canonical_source_id,source_type,payload) VALUES(?,?,?,?,'INSTAGRAM_REEL','{}')",UUID.randomUUID(),capture,user,source);
            ledger.reserveCapture(user,source,capture);
        });
        return new Fixture(user,source,capture);
    }
    private int count(String suffix) { return db.jdbc().queryForObject("SELECT count(*) FROM " + suffix,Integer.class); }
    private int used(UUID user) { return db.jdbc().queryForObject("SELECT monthly_capture_count FROM user_subscriptions WHERE user_id=?",Integer.class,user); }
    private String jobStatus() { return db.jdbc().queryForObject("SELECT status FROM ingestion_jobs",String.class); }
    private void due() { db.jdbc().update("UPDATE ingestion_jobs SET next_attempt_at=clock_timestamp()-INTERVAL '1 second'"); }
    record Fixture(UUID user,UUID source,UUID capture) {}
}
