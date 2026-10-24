package com.latyr.api;

import com.latyr.api.domain.enums.*;
import com.latyr.api.domain.model.*;
import com.latyr.api.dto.*;
import com.latyr.api.exception.LatyrException;
import com.latyr.api.mapper.*;
import com.latyr.api.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class CaptureServiceTest {
    private final CaptureMapper captures = mock(CaptureMapper.class);
    private final ExtractedEntityMapper entities = mock(ExtractedEntityMapper.class);
    private final IngestionJobMapper jobs = mock(IngestionJobMapper.class);
    private final CaptureQuotaLedger quota = mock(CaptureQuotaLedger.class);
    private final UrlNormalizationService urls = mock(UrlNormalizationService.class);
    private final CanonicalDeduplicationService sources = mock(CanonicalDeduplicationService.class);
    private final IngestionEventOutbox events = mock(IngestionEventOutbox.class);
    private final UUID userId = UUID.randomUUID();
    private final CanonicalSource source = new CanonicalSource();
    private CaptureService service;
    private static final String URL = "https://www.instagram.com/reel/C8xyz123/";

    @BeforeEach
    void setUp() {
        source.setId(UUID.randomUUID());
        source.setSourceType(SourceType.INSTAGRAM_REEL);
        source.setAiAnalysisCache(new HashMap<>());
        when(urls.getCanonicalUrlHash(anyString())).thenReturn("canonical-hash");
        when(sources.getOrCreateCanonicalSource(eq("canonical-hash"), any(), anyString())).thenReturn(source);
        service = new CaptureService(captures, entities, jobs, quota, urls, sources, events);
    }

    @Test
    void pendingAdmissionReservesWithoutChargingAndUsesOnlyDurableQueue() {
        CaptureResponse response = service.createUrlCapture(userId, new CreateCaptureRequest(URL, ContentType.URL, "my personal caption"));
        assertEquals(CaptureStatus.PENDING, response.status());
        verify(quota).lockAdmission(userId);
        verify(quota).reserveCapture(userId, source.getId(), response.id());
        verify(quota, never()).finalizeCapture(any());
        ArgumentCaptor<IngestionJob> job = ArgumentCaptor.forClass(IngestionJob.class);
        verify(jobs).insert(job.capture());
        assertEquals(Map.of("url", URL), job.getValue().getPayload());
        verifyNoInteractions(events);
    }

    @Test
    void sameUserReshareReturnsExistingCaptureEvenAtQuotaCap() {
        Capture existing = new Capture();
        existing.setId(UUID.randomUUID());
        existing.setUserId(userId);
        existing.setCanonicalSourceId(source.getId());
        existing.setStatus(CaptureStatus.COMPLETED);
        when(captures.findByUserIdAndCanonicalSourceId(userId, source.getId())).thenReturn(Optional.of(existing));
        CaptureResponse response = service.createUrlCapture(userId, new CreateCaptureRequest(URL, ContentType.URL, null));
        assertEquals(existing.getId(), response.id());
        verify(quota, never()).reserveCapture(any(), any(), any());
        verify(quota, never()).finalizeCapture(any());
        verify(captures, never()).insert(any());
        verifyNoInteractions(jobs, events);
    }

    @Test
    void reusedAnalysisChargesNewUserOnceAndPreservesFields() {
        Map<String,Object> cache = usefulCache();
        source.setAiAnalysisCache(cache);
        CaptureResponse response = service.createUrlCapture(userId, new CreateCaptureRequest(URL, ContentType.URL, "private override"));
        assertEquals(CaptureStatus.COMPLETED, response.status());
        assertEquals("Source title", response.title());
        assertEquals("Source summary", response.summary());
        assertEquals("Series", response.subCategory());
        assertEquals("Source caption", response.originalCaption());
        assertEquals("https://images.example.test/thumb.png", response.thumbnailUrl());
        verify(quota).reserveCapture(userId, source.getId(), response.id());
        verify(quota).finalizeCapture(response.id());
        verify(entities).insert(any());
        verify(events).append(eq(userId), eq("CAPTURE_COMPLETED"), argThat(p -> response.id().equals(p.get("capture_id"))));
        verify(jobs, never()).insert(any());
    }

    @Test
    void summaryOnlyCacheDoesNotQualifyAsSuccessfulCapture() {
        source.setAiAnalysisCache(Map.of("summary", "Useful sounding summary", "intent", "WATCH", "entities", List.of()));
        CaptureResponse response = service.createUrlCapture(userId, new CreateCaptureRequest(URL, ContentType.URL, null));
        assertEquals(CaptureStatus.PENDING, response.status());
        verify(quota, never()).finalizeCapture(any());
        verify(jobs).insert(any());
    }

    @Test
    void imageHashIncludesOwnerAndFitsDatabaseColumn() {
        UrlNormalizationService realUrls = new UrlNormalizationService();
        byte[] bytes = "private pixels".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        String hash = realUrls.computeSha256(userId + ":" + realUrls.computeSha256(bytes));
        when(sources.getOrCreateCanonicalSource(eq(hash), eq(SourceType.IMAGE), anyString())).thenReturn(source);
        source.setSourceType(SourceType.IMAGE);
        CaptureService realHashService = new CaptureService(captures, entities, jobs, quota, realUrls, sources, events);
        CaptureResponse response = realHashService.createImageCapture(userId, bytes, "screen.png");
        assertEquals(CaptureStatus.PENDING, response.status());
        assertEquals(64, hash.length());
        assertNotEquals(hash, realUrls.computeSha256(UUID.randomUUID() + ":" + realUrls.computeSha256(bytes)));
        verify(sources).getOrCreateCanonicalSource(hash, SourceType.IMAGE, "screen.png");
    }

    @Test
    void emptyImageRejectedBeforeQuotaOrSourceWrites() {
        LatyrException error = assertThrows(LatyrException.class, () -> service.createImageCapture(userId, new byte[0], "empty.png"));
        assertEquals("INVALID_IMAGE", error.getErrorCode());
        verifyNoInteractions(quota, captures, jobs);
    }

    @Test
    void internalUrlRejectedBeforeQuotaOrSourceWrites() {
        CaptureService realUrlService = new CaptureService(captures, entities, jobs, quota, new UrlNormalizationService(), sources, events);
        LatyrException error = assertThrows(LatyrException.class, () -> realUrlService.createUrlCapture(userId,
                new CreateCaptureRequest("http://127.0.0.1/private", ContentType.URL, null)));
        assertEquals("RESTRICTED_DESTINATION", error.getErrorCode());
        verifyNoInteractions(quota, captures, jobs);
    }

    @Test
    void cachedCoreWithoutEnrichmentQueuesOnlyEnrichmentRecovery() {
        Map<String,Object> cache = usefulCache();
        cache.remove("enrichment_status");
        source.setAiAnalysisCache(cache);
        CaptureResponse response = service.createUrlCapture(userId, new CreateCaptureRequest(URL, ContentType.URL, null));
        assertEquals(CaptureStatus.COMPLETED, response.status());
        ArgumentCaptor<IngestionJob> job = ArgumentCaptor.forClass(IngestionJob.class);
        verify(jobs).insert(job.capture());
        assertEquals(Boolean.TRUE, job.getValue().getPayload().get("enrichment_only"));
        verify(quota).finalizeCapture(response.id());
    }

    @Test
    void originalCaptureEntitiesCannotBeEdited() {
        LatyrException error = assertThrows(LatyrException.class, () -> service.updateEntity(userId, UUID.randomUUID(), null));
        assertEquals("CAPTURE_IMMUTABLE", error.getErrorCode());
        assertEquals(405, error.getHttpStatus().value());
        verifyNoInteractions(entities, captures);
    }

    private Map<String,Object> usefulCache() {
        Map<String,Object> cache = new HashMap<>();
        cache.put("intent", "WATCH");
        cache.put("enrichment_status", "ENRICHED");
        cache.put("category", "Entertainment");
        cache.put("sub_category", "Series");
        cache.put("title", "Source title");
        cache.put("summary", "Source summary");
        cache.put("original_caption", "Source caption");
        cache.put("thumbnail_url", "https://images.example.test/thumb.png");
        cache.put("entities", List.of(Map.of("title", "Dark", "entity_type", "TV_SHOW", "action_cta", "WATCH")));
        return cache;
    }
}
