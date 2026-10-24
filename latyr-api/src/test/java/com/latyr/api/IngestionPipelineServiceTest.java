package com.latyr.api;

import com.latyr.api.adapter.*;
import com.latyr.api.domain.enums.*;
import com.latyr.api.domain.model.*;
import com.latyr.api.exception.*;
import com.latyr.api.mapper.*;
import com.latyr.api.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class IngestionPipelineServiceTest {
    DurableIngestionStore store;
    CaptureMapper captures;
    CanonicalSourceMapper sources;
    ExtractedEntityMapper entities;
    ScraperProvider scraper;
    EphemeralMediaStreamer media;
    AIProvider ai;
    EntityEnrichmentProvider enricher;
    ThumbnailStorage thumbnails;
    CaptureQuotaLedger quota;
    IngestionEventOutbox events;
    IngestionPipelineService pipeline;
    IngestionJob job;
    Capture capture;
    CanonicalSource source;
    Map<String,Map<String,Object>> checkpoints;
    List<ExtractedEntity> saved;

    @BeforeEach void setup() {
        store = mock(DurableIngestionStore.class); captures = mock(CaptureMapper.class);
        sources = mock(CanonicalSourceMapper.class); entities = mock(ExtractedEntityMapper.class);
        scraper = mock(ScraperProvider.class); media = mock(EphemeralMediaStreamer.class);
        ai = mock(AIProvider.class); enricher = mock(EntityEnrichmentProvider.class);
        thumbnails = mock(ThumbnailStorage.class); quota = mock(CaptureQuotaLedger.class);
        events = mock(IngestionEventOutbox.class);
        pipeline = new IngestionPipelineService(store,captures,sources,entities,scraper,media,ai,enricher,thumbnails,quota,events);
        job = new IngestionJob(); job.setId(UUID.randomUUID()); job.setCaptureId(UUID.randomUUID());
        job.setCanonicalSourceId(UUID.randomUUID()); job.setUserId(UUID.randomUUID());
        job.setAttemptCount(1); job.setMaxAttempts(3); job.setSourceType(SourceType.INSTAGRAM_REEL);
        job.setPayload(Map.of("url","https://example.test/resource","caption","untrusted personal annotation"));
        capture = new Capture(); capture.setId(job.getCaptureId()); capture.setUserId(job.getUserId());
        capture.setCanonicalSourceId(job.getCanonicalSourceId()); capture.setSourceType(job.getSourceType());
        source = new CanonicalSource(); source.setId(job.getCanonicalSourceId()); source.setOriginalUrl("https://example.test/resource");
        when(captures.findById(job.getCaptureId())).thenReturn(Optional.of(capture));
        when(sources.findById(source.getId())).thenReturn(Optional.of(source));
        checkpoints = new HashMap<>(); saved = new ArrayList<>();
        doAnswer(call -> { call.getArgument(1,Runnable.class).run(); return null; }).when(store).withLease(eq(job),any());
        when(store.loadCheckpoint(eq(job),anyString())).thenAnswer(call -> checkpoints.get(call.getArgument(1,String.class)));
        doAnswer(call -> { checkpoints.put(call.getArgument(1,String.class),call.getArgument(2)); return null; })
            .when(store).completeStage(eq(job),anyString(),anyMap());
        when(store.retryOrFail(eq(job),anyBoolean(),anyString())).thenAnswer(call -> !call.getArgument(1,Boolean.class) || job.getAttemptCount() >= job.getMaxAttempts());
        when(entities.insert(any())).thenAnswer(call -> { saved.add(call.getArgument(0)); return 1; });
        when(entities.findByCaptureId(capture.getId())).thenAnswer(call -> saved);
        when(scraper.extractMedia(source.getOriginalUrl())).thenReturn(new ScraperProvider.ScrapedMedia(null,"https://example.test/audio",null,"Provider caption",null,60,Map.of()));
        when(media.streamMedia(any())).thenReturn(new byte[]{1});
        when(ai.analyzeMedia(any(),any(),any(),eq(Language.ORIGINAL))).thenReturn(analysis(null));
        when(enricher.enrichEntities(any())).thenAnswer(call -> call.getArgument(0));
    }

    static AIProvider.AIAnalysisResult analysis(String summary) {
        return new AIProvider.AIAnalysisResult("Grounded recommendation",summary,"Transcript",Intent.WATCH,
            "Entertainment","Movies",null,List.of(),List.of(new AIProvider.AIEntity(EntityType.MOVIE,"Dark",
                "Recommendation from source",null,ActionCTA.WATCH,Map.of())));
    }

    @Test void usefulIntentsSucceedWithoutSummaryAndCommitQuotaBeforeEnrichment() {
        when(enricher.enrichEntities(any())).thenAnswer(call -> {
            assertEquals(CaptureStatus.COMPLETED,capture.getStatus());
            verify(quota).finalizeCapture(capture.getId());
            return call.getArgument(0);
        });
        pipeline.processJob(job);
        assertEquals(CaptureStatus.COMPLETED,capture.getStatus());
        assertNull(capture.getSummary()); assertEquals(1,saved.size());
        verify(ai).analyzeMedia(any(),eq("audio/mp3"),eq("Provider caption"),eq(Language.ORIGINAL));
        verify(events).append(eq(job.getUserId()),eq("CAPTURE_COMPLETED"),anyMap());
        verify(store).complete(job);
        verify(quota,never()).releaseCapture(any());
    }

    @Test void sourceFailureSchedulesRetryWithoutFinalizingOrReleasingReservation() {
        when(scraper.extractMedia(any())).thenThrow(new ProviderOperationException("SCRAPER_RATE_LIMITED",ProviderOperationException.Outcome.RETRYABLE));
        pipeline.processJob(job);
        verify(store).retryOrFail(job,true,"SCRAPER_RATE_LIMITED");
        verifyNoInteractions(ai,quota);
        assertNotEquals(CaptureStatus.COMPLETED,capture.getStatus());
    }

    @Test void exhaustedSourceFailureReleasesReservationAndReportsFailure() {
        job.setAttemptCount(3);
        when(scraper.extractMedia(any())).thenThrow(new ProviderOperationException("SCRAPER_UNAVAILABLE",ProviderOperationException.Outcome.RETRYABLE));
        pipeline.processJob(job);
        assertEquals(CaptureStatus.FAILED,capture.getStatus());
        verify(quota).releaseCapture(capture.getId()); verify(quota,never()).finalizeCapture(any());
        verify(events).append(eq(job.getUserId()),eq("CAPTURE_FAILED"),anyMap());
    }

    @Test void summaryOnlyIsPartialAndNeverCharged() {
        var empty = new AIProvider.AIAnalysisResult("Summary only","Useful summary","Source",Intent.EXPLORE,
            "General",null,null,List.of(),List.of());
        when(ai.analyzeMedia(any(),any(),any(),any())).thenReturn(empty);
        pipeline.processJob(job);
        assertEquals(CaptureStatus.PARTIAL,capture.getStatus());
        verify(quota).releaseCapture(capture.getId()); verify(quota,never()).finalizeCapture(any());
        verifyNoInteractions(enricher);
        assertTrue(checkpoints.containsKey("ANALYSIS"));
    }

    @Test void enrichmentFailureCannotUndoSuccessAndRetryCannotRerunAi() {
        when(enricher.enrichEntities(any())).thenThrow(new ProviderOperationException("ENRICHMENT_UNAVAILABLE",ProviderOperationException.Outcome.RETRYABLE))
            .thenAnswer(call -> call.getArgument(0));
        pipeline.processJob(job);
        assertEquals(CaptureStatus.COMPLETED,capture.getStatus());
        assertEquals(1,saved.size());
        job.setAttemptCount(2); pipeline.processJob(job);
        verify(ai,times(1)).analyzeMedia(any(),any(),any(),any());
        verify(scraper,times(1)).extractMedia(any());
        verify(quota,times(1)).finalizeCapture(capture.getId()); verify(store).complete(job);
        assertEquals(1,saved.size());
    }

    @Test void ambiguousAiOutcomeStopsAndReleasesQuotaWithoutInventingIntents() {
        when(ai.analyzeMedia(any(),any(),any(),any())).thenThrow(new RuntimeException("timeout containing private content"));
        pipeline.processJob(job);
        verify(store).failStage(job,"ANALYSIS","AI_OUTCOME_UNKNOWN");
        verify(store).retryOrFail(job,false,"AI_OUTCOME_UNKNOWN");
        assertEquals(CaptureStatus.PARTIAL,capture.getStatus()); assertTrue(saved.isEmpty());
        verify(quota).releaseCapture(capture.getId());
    }

    @Test void staleExecutionMakesNoProviderCallsOrWrites() {
        doThrow(new IngestionLeaseLostException()).when(store).withLease(eq(job),any());
        pipeline.processJob(job);
        verifyNoInteractions(scraper,media,ai,enricher,quota,captures,events);
    }

    @Test void reclaimedExhaustedJobNeverCallsProviders() {
        job.setAttemptCount(4); pipeline.processJob(job);
        verifyNoInteractions(scraper,media,ai,enricher);
        verify(quota).releaseCapture(capture.getId());
        verify(store).retryOrFail(job,false,"ATTEMPTS_EXHAUSTED");
    }

    @Test void successfulSharedCheckpointAvoidsEveryAcquisitionAndAiCall() {
        checkpoints.put("ANALYSIS",CaptureAnalysisCodec.encode(analysis("Summary")));
        pipeline.processJob(job);
        verifyNoInteractions(scraper,media,ai);
        assertEquals(CaptureStatus.COMPLETED,capture.getStatus());
    }

    @Test void legacyEnrichmentOnlyNeverCallsAiOrChangesCoreQuota() {
        capture.setStatus(CaptureStatus.COMPLETED); capture.setIntent(Intent.WATCH);
        capture.setTitle("Existing title");
        ExtractedEntity entity = new ExtractedEntity(); entity.setId(UUID.randomUUID());
        entity.setCaptureId(capture.getId()); entity.setTitle("Dark"); entity.setEntityType(EntityType.MOVIE);
        entity.setActionCta(ActionCTA.WATCH); saved.add(entity);
        job.setPayload(Map.of("enrichment_only",true));
        pipeline.processJob(job);
        verifyNoInteractions(scraper,media,ai,quota);
        assertEquals("Existing title",capture.getTitle()); verify(store).complete(job);
    }
}
