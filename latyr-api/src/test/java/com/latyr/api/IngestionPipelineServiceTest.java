package com.latyr.api;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.EntityEnrichmentProvider;
import com.latyr.api.adapter.EphemeralMediaStreamer;
import com.latyr.api.adapter.ScraperProvider;
import com.latyr.api.domain.enums.*;
import com.latyr.api.domain.model.*;
import com.latyr.api.mapper.*;
import com.latyr.api.service.IngestionPipelineService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class IngestionPipelineServiceTest {

    private IngestionJobMapper ingestionJobMapper;
    private CaptureMapper captureMapper;
    private CanonicalSourceMapper canonicalSourceMapper;
    private ExtractedEntityMapper extractedEntityMapper;
    private UserMapper userMapper;
    private ScraperProvider scraperProvider;
    private EphemeralMediaStreamer mediaStreamer;
    private AIProvider aiProvider;
    private EntityEnrichmentProvider entityEnricher;
    private com.latyr.api.service.SseNotificationService sseNotificationService;
    private com.latyr.api.service.FcmService fcmService;

    private IngestionPipelineService pipelineService;

    @BeforeEach
    void setUp() {
        ingestionJobMapper = mock(IngestionJobMapper.class);
        captureMapper = mock(CaptureMapper.class);
        canonicalSourceMapper = mock(CanonicalSourceMapper.class);
        extractedEntityMapper = mock(ExtractedEntityMapper.class);
        userMapper = mock(UserMapper.class);
        scraperProvider = mock(ScraperProvider.class);
        mediaStreamer = mock(EphemeralMediaStreamer.class);
        aiProvider = mock(AIProvider.class);
        entityEnricher = mock(EntityEnrichmentProvider.class);
        sseNotificationService = mock(com.latyr.api.service.SseNotificationService.class);
        fcmService = mock(com.latyr.api.service.FcmService.class);

        pipelineService = new IngestionPipelineService(
                ingestionJobMapper,
                captureMapper,
                canonicalSourceMapper,
                extractedEntityMapper,
                userMapper,
                scraperProvider,
                mediaStreamer,
                aiProvider,
                entityEnricher,
                sseNotificationService,
                fcmService
        );
    }

    @Test
    @DisplayName("Pipeline Success: Scrape -> Audio -> AI -> Enrich -> DB Persist (Capture & Entities)")
    void testProcessJob_Success() {
        UUID userId = UUID.randomUUID();
        UUID captureId = UUID.randomUUID();
        UUID sourceId = UUID.randomUUID();
        UUID jobId = UUID.randomUUID();

        User user = new User();
        user.setId(userId);
        user.setLanguage(Language.HINGLISH);
        when(userMapper.findById(userId)).thenReturn(Optional.of(user));

        Capture capture = new Capture();
        capture.setId(captureId);
        capture.setUserId(userId);
        capture.setCanonicalSourceId(sourceId);
        capture.setStatus(CaptureStatus.PENDING);
        when(captureMapper.findById(captureId)).thenReturn(Optional.of(capture));

        CanonicalSource canonicalSource = new CanonicalSource();
        canonicalSource.setId(sourceId);
        canonicalSource.setOriginalUrl("https://www.instagram.com/reel/C8xyz123/");
        when(canonicalSourceMapper.findById(sourceId)).thenReturn(Optional.of(canonicalSource));

        IngestionJob job = new IngestionJob();
        job.setId(jobId);
        job.setCaptureId(captureId);
        job.setUserId(userId);
        job.setSourceType(SourceType.INSTAGRAM_REEL);
        job.setPayload(Map.of("url", "https://www.instagram.com/reel/C8xyz123/"));
        job.setStatus(JobStatus.PROCESSING);
        job.setAttemptCount(0);
        job.setMaxAttempts(3);

        ScraperProvider.ScrapedMedia scraped = new ScraperProvider.ScrapedMedia(
                "https://cdn.latyr.internal/video.mp4",
                "https://cdn.latyr.internal/audio.mp3",
                "5 suspense movies you must watch",
                "Movie list",
                60,
                Map.of()
        );
        when(scraperProvider.extractMedia(any())).thenReturn(scraped);

        byte[] audioBytes = "test-audio-stream".getBytes();
        when(mediaStreamer.streamMedia(any())).thenReturn(audioBytes);

        AIProvider.AIEntity aiEntity = new AIProvider.AIEntity(
                EntityType.TV_SHOW,
                "Dark",
                "German sci-fi mystery",
                "https://netflix.com/dark",
                ActionCTA.WATCH,
                new HashMap<>()
        );
        AIProvider.AIAnalysisResult analysis = new AIProvider.AIAnalysisResult(
                "Transcript: watch these 5 movies...",
                Intent.WATCH,
                "Entertainment",
                "Thriller Shows",
                List.of("Weekend movie recommendation"),
                List.of(aiEntity)
        );
        when(aiProvider.analyzeMedia(any(), any(), any(), eq(Language.HINGLISH))).thenReturn(analysis);
        when(entityEnricher.enrichEntities(any())).thenReturn(List.of(aiEntity));

        // Execute pipeline
        pipelineService.processJob(job);

        // Verify Capture updated to COMPLETED
        assertEquals(CaptureStatus.COMPLETED, capture.getStatus());
        assertEquals(Intent.WATCH, capture.getIntent());
        assertEquals("Entertainment", capture.getCategory());
        assertEquals("5 suspense movies you must watch", capture.getOriginalCaption());
        verify(captureMapper, times(1)).update(capture);

        // Verify CanonicalSource cache updated
        assertNotNull(canonicalSource.getAiAnalysisCache());
        verify(canonicalSourceMapper, times(1)).update(canonicalSource);

        // Verify ExtractedEntity inserted
        verify(extractedEntityMapper, times(1)).insert(any(ExtractedEntity.class));

        // Verify IngestionJob marked COMPLETED
        assertEquals(JobStatus.COMPLETED, job.getStatus());
        verify(ingestionJobMapper, times(1)).update(job);
    }

    @Test
    @DisplayName("Transient Failure: Increments attempt count and resets job to PENDING")
    void testProcessJob_TransientFailure_RequeuesJob() {
        UUID userId = UUID.randomUUID();
        UUID captureId = UUID.randomUUID();
        UUID sourceId = UUID.randomUUID();
        UUID jobId = UUID.randomUUID();

        User user = new User();
        user.setId(userId);
        when(userMapper.findById(userId)).thenReturn(Optional.of(user));

        Capture capture = new Capture();
        capture.setId(captureId);
        capture.setCanonicalSourceId(sourceId);
        when(captureMapper.findById(captureId)).thenReturn(Optional.of(capture));

        CanonicalSource canonicalSource = new CanonicalSource();
        canonicalSource.setId(sourceId);
        when(canonicalSourceMapper.findById(sourceId)).thenReturn(Optional.of(canonicalSource));

        IngestionJob job = new IngestionJob();
        job.setId(jobId);
        job.setCaptureId(captureId);
        job.setUserId(userId);
        job.setSourceType(SourceType.INSTAGRAM_REEL);
        job.setPayload(Map.of("url", "https://instagram.com/reel/error/"));
        job.setStatus(JobStatus.PROCESSING);
        job.setAttemptCount(0);
        job.setMaxAttempts(3);

        when(scraperProvider.extractMedia(any())).thenThrow(new RuntimeException("Apify network timeout"));

        // Execute pipeline
        pipelineService.processJob(job);

        assertEquals(1, job.getAttemptCount());
        assertEquals(JobStatus.PENDING, job.getStatus()); // Requeued for exponential backoff
        assertNull(job.getLockedAt());
        assertNull(job.getLockedBy());
        verify(ingestionJobMapper, times(1)).update(job);
    }

    @Test
    @DisplayName("Max Retries Exceeded: Marks job and capture as FAILED")
    void testProcessJob_MaxAttemptsReached_MarksFailed() {
        UUID userId = UUID.randomUUID();
        UUID captureId = UUID.randomUUID();
        UUID sourceId = UUID.randomUUID();
        UUID jobId = UUID.randomUUID();

        User user = new User();
        user.setId(userId);
        when(userMapper.findById(userId)).thenReturn(Optional.of(user));

        Capture capture = new Capture();
        capture.setId(captureId);
        capture.setCanonicalSourceId(sourceId);
        capture.setStatus(CaptureStatus.PENDING);
        when(captureMapper.findById(captureId)).thenReturn(Optional.of(capture));

        CanonicalSource canonicalSource = new CanonicalSource();
        canonicalSource.setId(sourceId);
        when(canonicalSourceMapper.findById(sourceId)).thenReturn(Optional.of(canonicalSource));

        IngestionJob job = new IngestionJob();
        job.setId(jobId);
        job.setCaptureId(captureId);
        job.setUserId(userId);
        job.setSourceType(SourceType.INSTAGRAM_REEL);
        job.setPayload(Map.of("url", "https://instagram.com/reel/fatal/"));
        job.setStatus(JobStatus.PROCESSING);
        job.setAttemptCount(2); // On 3rd failure, max reached
        job.setMaxAttempts(3);

        when(scraperProvider.extractMedia(any())).thenThrow(new RuntimeException("Fatal scraping error"));

        // Execute pipeline
        pipelineService.processJob(job);

        assertEquals(3, job.getAttemptCount());
        assertEquals(JobStatus.FAILED, job.getStatus());
        verify(ingestionJobMapper, times(1)).update(job);

        assertEquals(CaptureStatus.FAILED, capture.getStatus());
        verify(captureMapper, times(1)).update(capture);
    }
}
