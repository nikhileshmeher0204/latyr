package com.latyr.api;

import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.SourceType;
import com.latyr.api.domain.model.CanonicalSource;
import com.latyr.api.domain.model.Capture;
import com.latyr.api.domain.model.ExtractedEntity;
import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.dto.CaptureResponse;
import com.latyr.api.dto.CreateCaptureRequest;
import com.latyr.api.mapper.CaptureMapper;
import com.latyr.api.mapper.ExtractedEntityMapper;
import com.latyr.api.mapper.IngestionJobMapper;
import com.latyr.api.service.CanonicalDeduplicationService;
import com.latyr.api.service.CaptureService;
import com.latyr.api.service.SubscriptionQuotaService;
import com.latyr.api.service.UrlNormalizationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class CaptureServiceTest {

    private CaptureMapper captureMapper;
    private ExtractedEntityMapper extractedEntityMapper;
    private IngestionJobMapper ingestionJobMapper;
    private SubscriptionQuotaService quotaService;
    private UrlNormalizationService urlNormalizationService;
    private CanonicalDeduplicationService deduplicationService;
    private com.latyr.api.worker.IngestionQueueWorker queueWorker;

    private CaptureService captureService;

    @BeforeEach
    void setUp() {
        captureMapper = Mockito.mock(CaptureMapper.class);
        extractedEntityMapper = Mockito.mock(ExtractedEntityMapper.class);
        ingestionJobMapper = Mockito.mock(IngestionJobMapper.class);
        quotaService = Mockito.mock(SubscriptionQuotaService.class);
        urlNormalizationService = new UrlNormalizationService();
        deduplicationService = Mockito.mock(CanonicalDeduplicationService.class);
        queueWorker = Mockito.mock(com.latyr.api.worker.IngestionQueueWorker.class);

        captureService = new CaptureService(
                captureMapper,
                extractedEntityMapper,
                ingestionJobMapper,
                quotaService,
                urlNormalizationService,
                deduplicationService,
                queueWorker
        );
    }

    @Test
    @DisplayName("Cache Miss: Should enqueue IngestionJob and return status PENDING")
    void testCreateUrlCapture_CacheMiss() {
        UUID userId = UUID.randomUUID();
        CreateCaptureRequest request = new CreateCaptureRequest("https://www.instagram.com/reel/C8xyz123/?igsh=abc", ContentType.URL);
        String canonicalHash = urlNormalizationService.getCanonicalUrlHash(request.url());

        when(deduplicationService.findCachedSource(canonicalHash)).thenReturn(Optional.empty());

        CanonicalSource canonicalSource = new CanonicalSource();
        canonicalSource.setId(UUID.randomUUID());
        canonicalSource.setCanonicalUrlHash(canonicalHash);
        when(deduplicationService.getOrCreateCanonicalSource(eq(canonicalHash), eq(SourceType.INSTAGRAM_REEL), eq(request.url())))
                .thenReturn(canonicalSource);

        CaptureResponse response = captureService.createUrlCapture(userId, request);

        assertNotNull(response);
        assertEquals(CaptureStatus.PENDING, response.status());
        verify(quotaService, times(1)).verifyAndIncrementQuota(userId);
        verify(captureMapper, times(1)).insert(any(Capture.class));
        verify(ingestionJobMapper, times(1)).insert(any(IngestionJob.class));
    }

    @Test
    @DisplayName("Cache Hit: Should immediately complete capture, copy entities, and skip IngestionJob")
    void testCreateUrlCapture_CacheHit() {
        UUID userId = UUID.randomUUID();
        CreateCaptureRequest request = new CreateCaptureRequest("https://www.instagram.com/reel/C8xyz123/", ContentType.URL);
        String canonicalHash = urlNormalizationService.getCanonicalUrlHash(request.url());

        CanonicalSource cachedSource = new CanonicalSource();
        cachedSource.setId(UUID.randomUUID());
        cachedSource.setCanonicalUrlHash(canonicalHash);

        Map<String, Object> aiCache = new HashMap<>();
        aiCache.put("intent", "WATCH");
        aiCache.put("category", "Entertainment");
        aiCache.put("original_caption", "5 movies to watch");
        aiCache.put("audio_transcript", "Here are 5 movies...");
        aiCache.put("notification_copies", List.of("Movie recommendation for your weekend"));
        aiCache.put("entities", List.of(
                Map.of("title", "Dark", "entity_type", "TV_SHOW", "action_cta", "WATCH")
        ));
        cachedSource.setAiAnalysisCache(aiCache);

        when(deduplicationService.findCachedSource(canonicalHash)).thenReturn(Optional.of(cachedSource));

        CaptureResponse response = captureService.createUrlCapture(userId, request);

        assertNotNull(response);
        assertEquals(CaptureStatus.COMPLETED, response.status());
        assertEquals(Intent.WATCH, response.intent());
        assertEquals("Entertainment", response.category());

        verify(quotaService, times(1)).verifyAndIncrementQuota(userId);
        verify(captureMapper, times(1)).insert(any(Capture.class));
        verify(extractedEntityMapper, times(1)).insert(any(ExtractedEntity.class));
        verify(ingestionJobMapper, never()).insert(any(IngestionJob.class)); // $0 AI cost!
    }
}
