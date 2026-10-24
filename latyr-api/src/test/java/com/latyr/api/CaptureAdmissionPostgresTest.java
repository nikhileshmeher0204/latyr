package com.latyr.api;

import com.latyr.api.domain.enums.*;
import com.latyr.api.dto.*;
import com.latyr.api.exception.QuotaExceededException;
import com.latyr.api.mapper.*;
import com.latyr.api.service.*;
import com.latyr.api.support.PostgresTestDatabase;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Supplier;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@EnabledIfEnvironmentVariable(named = "TEST_DATABASE_URL", matches = ".+")
class CaptureAdmissionPostgresTest {
    private PostgresTestDatabase db;
    private CaptureQuotaLedger ledger;
    private CaptureService admission;
    private SubscriptionQuotaService subscriptions;
    private CanonicalDeduplicationService sources;
    private UUID user;

    @BeforeEach
    void setUp() throws Exception {
        db = new PostgresTestDatabase();
        subscriptions = new SubscriptionQuotaService(db.mapper(UserSubscriptionMapper.class),
                db.mapper(UserSubscriptionHistoryMapper.class), db.mapper(UserMapper.class));
        ledger = new CaptureQuotaLedger(db.mapper(CaptureQuotaLedgerMapper.class), subscriptions,
                db.mapper(UserSubscriptionMapper.class));
        sources = new CanonicalDeduplicationService(db.mapper(CanonicalSourceMapper.class));
        UrlNormalizationService urls = spy(new UrlNormalizationService());
        doNothing().when(urls).validateOutboundUrl(anyString());
        admission = new CaptureService(db.mapper(CaptureMapper.class), db.mapper(ExtractedEntityMapper.class),
                db.mapper(IngestionJobMapper.class), ledger, urls, sources,
                new IngestionEventOutbox(db.mapper(IngestionOutboxMapper.class)));
        user = newUser();
    }

    @AfterEach
    void tearDown() { if (db != null) db.close(); }

    @Test
    void concurrentFirstAdmissionsForSameSourceCreateOneCaptureAndReservation() throws Exception {
        setLimit(user, 1);
        List<CaptureResponse> responses = parallel(8, () -> create(user, "https://example.test/same"));
        assertEquals(1, responses.stream().map(CaptureResponse::id).distinct().count());
        assertEquals(1, count("captures"));
        assertEquals(1, count("ingestion_jobs"));
        assertEquals(1, count("capture_quota_ledger"));
        assertEquals(0, used(user));
    }

    @Test
    void concurrentDifferentSourcesCannotExceedReservedCapacity() throws Exception {
        setLimit(user, 1);
        java.util.concurrent.atomic.AtomicInteger index = new java.util.concurrent.atomic.AtomicInteger();
        List<Boolean> admitted = parallel(8, () -> {
            try { create(user, "https://example.test/item/" + index.incrementAndGet()); return true; }
            catch (QuotaExceededException expected) { return false; }
        });
        assertEquals(1, admitted.stream().filter(Boolean::booleanValue).count());
        assertEquals(1, count("captures"));
        assertEquals(1, count("ingestion_jobs"));
        assertEquals(0, used(user));
    }

    @Test
    void concurrentFinalizationChargesExactlyOnceAndReshareRemainsFreeAtCap() throws Exception {
        setLimit(user, 1);
        CaptureResponse capture = create(user, "https://example.test/once");
        parallel(8, () -> tx(() -> { ledger.finalizeCapture(capture.id()); return true; }));
        assertEquals(1, used(user));
        assertEquals("FINALIZED", state(capture.id()));
        assertEquals(capture.id(), create(user, "https://example.test/once").id());
        tx(() -> { ledger.releaseCapture(capture.id()); return null; });
        assertEquals(1, used(user));
    }

    @Test
    void failedCaptureReleasesCapacityWithoutSuccessfulCharge() {
        setLimit(user, 1);
        CaptureResponse first = create(user, "https://example.test/failure");
        tx(() -> { ledger.releaseCapture(first.id()); ledger.releaseCapture(first.id()); return null; });
        assertEquals("RELEASED", state(first.id()));
        assertEquals(0, used(user));
        assertNotNull(create(user, "https://example.test/replacement"));
    }

    @Test
    void staleBillingSnapshotCannotEraseFinalizedCaptureCount() {
        CaptureResponse capture = create(user, "https://example.test/billing-race");
        var snapshot = db.mapper(UserSubscriptionMapper.class).findByUserId(user).orElseThrow();
        assertEquals(0, snapshot.getMonthlyCaptureCount());
        tx(() -> { ledger.finalizeCapture(capture.id()); return null; });
        snapshot.setPlanTier(PlanTier.PRO);
        snapshot.setQuotaLimit(1000);
        db.mapper(UserSubscriptionMapper.class).update(snapshot);
        assertEquals(1, used(user));
    }

    @Test
    void cycleResetCarriesReservationsAndConcurrentFinalizationsDoNotEraseCounts() throws Exception {
        setLimit(user, 2);
        CaptureResponse first = create(user, "https://example.test/before-reset/1");
        CaptureResponse second = create(user, "https://example.test/before-reset/2");
        db.jdbc().update("UPDATE user_subscriptions SET monthly_capture_count=2, quota_reset_at=CURRENT_TIMESTAMP-INTERVAL '1 day' WHERE user_id=?", user);
        assertThrows(QuotaExceededException.class, () -> create(user, "https://example.test/capacity-held"));
        List<UUID> ids = List.of(first.id(), second.id());
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            var futures = ids.stream().map(id -> executor.submit(() -> tx(() -> { ledger.finalizeCapture(id); return null; }))).toList();
            for (Future<?> future : futures) future.get(10, TimeUnit.SECONDS);
        }
        assertEquals(2, used(user));
        assertEquals(0, db.mapper(CaptureQuotaLedgerMapper.class).countReservations(user));
    }

    @Test
    void reusedPublicAnalysisChargesEachNewUserAndCachesCompleteFieldsAtomically() {
        UUID other = newUser();
        String url = "https://example.test/public";
        String hash = new UrlNormalizationService().getCanonicalUrlHash(url);
        UUID source = tx(() -> sources.getOrCreateCanonicalSource(hash, SourceType.WEB_URL, url).getId());
        db.jdbc().update("""
            UPDATE canonical_sources SET ai_analysis_cache=?::jsonb WHERE id=?
            """, """
            {"intent":"WATCH","enrichment_status":"ENRICHED","title":"Original title","summary":"Original summary","category":"Entertainment",
             "sub_category":"Series","original_caption":"Original caption","thumbnail_url":"https://example.test/thumb.png",
             "entities":[{"title":"Dark","entity_type":"TV_SHOW","action_cta":"WATCH"}]}
            """, source);
        CaptureResponse one = create(user, url);
        CaptureResponse two = create(other, url);
        assertEquals(CaptureStatus.COMPLETED, one.status());
        assertEquals(CaptureStatus.COMPLETED, two.status());
        assertNotEquals(one.id(), two.id());
        assertEquals(1, used(user));
        assertEquals(1, used(other));
        assertEquals(2, count("extracted_entities"));
        assertEquals(0, count("ingestion_jobs"));
        assertEquals("Original title", one.title());
        assertEquals("Original summary", one.summary());
        assertEquals("Series", one.subCategory());
        assertEquals("https://example.test/thumb.png", one.thumbnailUrl());
    }

    @Test
    void admissionRollbackLeavesNoCaptureReservationOrRunnableJob() {
        assertThrows(IllegalStateException.class, () -> tx(() -> {
            admission.createUrlCapture(user, new CreateCaptureRequest("https://example.test/rollback", ContentType.URL, null));
            throw new IllegalStateException("rollback fixture");
        }));
        assertEquals(0, count("captures"));
        assertEquals(0, count("ingestion_jobs"));
        assertEquals(0, count("capture_quota_ledger"));
    }

    private UUID newUser() {
        UUID id = UUID.randomUUID();
        db.jdbc().update("INSERT INTO users(id,firebase_uid,email) VALUES(?,?,?)", id, "fixture-" + id, id + "@example.test");
        return id;
    }
    private void setLimit(UUID id, int limit) {
        tx(() -> { ledger.lockAdmission(id); return null; });
        db.jdbc().update("UPDATE user_subscriptions SET quota_limit=? WHERE user_id=?", limit, id);
    }
    private CaptureResponse create(UUID id, String url) {
        return tx(() -> admission.createUrlCapture(id, new CreateCaptureRequest(url, ContentType.URL, null)));
    }
    private <T> T tx(Supplier<T> action) { return db.transactions().execute(status -> action.get()); }
    private int used(UUID id) { return db.jdbc().queryForObject("SELECT monthly_capture_count FROM user_subscriptions WHERE user_id=?", Integer.class, id); }
    private int count(String table) { return db.jdbc().queryForObject("SELECT count(*) FROM " + table, Integer.class); }
    private String state(UUID id) { return db.jdbc().queryForObject("SELECT state FROM capture_quota_ledger WHERE capture_id=?", String.class, id); }
    private <T> List<T> parallel(int count, Callable<T> action) throws Exception {
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            CountDownLatch ready = new CountDownLatch(count);
            CountDownLatch go = new CountDownLatch(1);
            List<Future<T>> futures = new ArrayList<>();
            for (int i=0;i<count;i++) futures.add(executor.submit(() -> { ready.countDown(); go.await(); return action.call(); }));
            assertTrue(ready.await(5, TimeUnit.SECONDS));
            go.countDown();
            List<T> results = new ArrayList<>();
            for (Future<T> future : futures) results.add(future.get(15, TimeUnit.SECONDS));
            return results;
        }
    }
}
