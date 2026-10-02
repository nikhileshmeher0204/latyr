package com.latyr.api.service;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.EntityEnrichmentProvider;
import com.latyr.api.adapter.EphemeralMediaStreamer;
import com.latyr.api.adapter.ScraperProvider;
import com.latyr.api.domain.enums.*;
import com.latyr.api.domain.model.*;
import com.latyr.api.mapper.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class IngestionPipelineService {

    private static final Logger log = LoggerFactory.getLogger(IngestionPipelineService.class);

    private final IngestionJobMapper ingestionJobMapper;
    private final CaptureMapper captureMapper;
    private final CanonicalSourceMapper canonicalSourceMapper;
    private final ExtractedEntityMapper extractedEntityMapper;
    private final UserMapper userMapper;
    private final ScraperProvider scraperProvider;
    private final EphemeralMediaStreamer mediaStreamer;
    private final AIProvider aiProvider;
    private final EntityEnrichmentProvider entityEnricher;
    private final SseNotificationService sseNotificationService;
    private final FcmService fcmService;
    private final FirebaseStorageService firebaseStorageService;

    public IngestionPipelineService(
            IngestionJobMapper ingestionJobMapper,
            CaptureMapper captureMapper,
            CanonicalSourceMapper canonicalSourceMapper,
            ExtractedEntityMapper extractedEntityMapper,
            UserMapper userMapper,
            ScraperProvider scraperProvider,
            EphemeralMediaStreamer mediaStreamer,
            AIProvider aiProvider,
            EntityEnrichmentProvider entityEnricher,
            SseNotificationService sseNotificationService,
            FcmService fcmService,
            @org.springframework.beans.factory.annotation.Autowired(required = false) FirebaseStorageService firebaseStorageService) {
        this.ingestionJobMapper = ingestionJobMapper;
        this.captureMapper = captureMapper;
        this.canonicalSourceMapper = canonicalSourceMapper;
        this.extractedEntityMapper = extractedEntityMapper;
        this.userMapper = userMapper;
        this.scraperProvider = scraperProvider;
        this.mediaStreamer = mediaStreamer;
        this.aiProvider = aiProvider;
        this.entityEnricher = entityEnricher;
        this.sseNotificationService = sseNotificationService;
        this.fcmService = fcmService;
        this.firebaseStorageService = firebaseStorageService;
    }

    @Transactional
    public void processJob(IngestionJob job) {
        long startTimeMs = System.currentTimeMillis();
        UUID jobId = job.getId();
        UUID captureId = job.getCaptureId();
        UUID userId = job.getUserId();

        log.info("Starting ingestion processing for job {} (capture: {}, user: {})", jobId, captureId, userId);

        try {
            User user = userMapper.findById(userId).orElse(null);
            Language userLanguage = user != null && user.getLanguage() != null ? user.getLanguage() : Language.ENGLISH;

            Capture capture = captureMapper.findById(captureId)
                    .orElseThrow(() -> new IllegalStateException("Capture not found: " + captureId));

            // Mark capture and job as PROCESSING and notify mobile client via SSE
            capture.setStatus(CaptureStatus.PROCESSING);
            capture.setUpdatedAt(Instant.now());
            captureMapper.update(capture);

            job.setStatus(JobStatus.PROCESSING);
            job.setUpdatedAt(Instant.now());
            ingestionJobMapper.update(job);

            if (sseNotificationService != null) {
                sseNotificationService.emitCaptureEvent(userId, "CAPTURE_PROCESSING", Map.of(
                        "capture_id", captureId,
                        "status", "PROCESSING"
                ));
            }

            CanonicalSource canonicalSource = canonicalSourceMapper.findById(capture.getCanonicalSourceId())
                    .orElseThrow(() -> new IllegalStateException("CanonicalSource not found: " + capture.getCanonicalSourceId()));

            AIProvider.AIAnalysisResult analysis;
            String caption = null;
            Integer videoDurationSec = null;

            if (job.getSourceType() == SourceType.IMAGE) {
                // Image / Screenshot Ingestion
                String base64 = job.getPayload() != null ? (String) job.getPayload().get("image_base64") : null;
                byte[] imageBytes = base64 != null ? Base64.getDecoder().decode(base64) : new byte[0];
                analysis = aiProvider.analyzeImage(imageBytes, "image/png", userLanguage);
                caption = "Screenshot capture";
            } else {
                // URL / Social Reel Ingestion
                String rawUrl = (String) job.getPayload().get("url");
                if (rawUrl == null || rawUrl.trim().isEmpty()) {
                    rawUrl = canonicalSource.getOriginalUrl();
                }

                // Step 1: Scrape media metadata
                ScraperProvider.ScrapedMedia scraped = scraperProvider.extractMedia(rawUrl);
                String jobCaption = job.getPayload() != null ? (String) job.getPayload().get("caption") : null;
                if (jobCaption != null && !jobCaption.isBlank()) {
                    caption = jobCaption;
                } else {
                    caption = scraped.caption();
                }
                videoDurationSec = scraped.durationSec();

                // Step 1.1: Persist thumbnail to Firebase Storage (with fallback)
                String rawThumbnailUrl = scraped.thumbnailUrl();
                String finalThumbnailUrl = rawThumbnailUrl;
                if (firebaseStorageService != null && rawThumbnailUrl != null && !rawThumbnailUrl.isBlank()) {
                    finalThumbnailUrl = firebaseStorageService.uploadImageFromUrl(rawThumbnailUrl, captureId);
                }

                // Step 2: Ephemeral in-memory audio download (capped at 15MB)
                byte[] audioBytes = mediaStreamer.streamMedia(scraped.audioUrl());

                // Step 3: Multimodal Gemini AI inference
                analysis = aiProvider.analyzeMedia(audioBytes, "audio/mp3", caption, userLanguage);

                // Step 4: Immediate memory dereferencing for JVM Garbage Collection
                audioBytes = null;

                canonicalSource.setThumbnailUrl(finalThumbnailUrl);
                capture.setThumbnailUrl(finalThumbnailUrl);
            }

            // Step 5: Secondary Entity Enrichment (TMDB & GitHub)
            List<AIProvider.AIEntity> enrichedEntities = entityEnricher.enrichEntities(analysis.entities());

            // Step 6: Atomic DB Persistence
            // 6.1 Update CanonicalSource 30-day cache
            Map<String, Object> cacheMap = new HashMap<>();
            cacheMap.put("title", analysis.title());
            cacheMap.put("transcript", analysis.transcript());
            cacheMap.put("intent", analysis.intent().name());
            cacheMap.put("category", analysis.category());
            cacheMap.put("sub_category", analysis.subCategory());
            cacheMap.put("suggested_collection", analysis.suggestedCollection());
            cacheMap.put("notification_copies", analysis.notificationCopies());
            cacheMap.put("original_caption", caption);
            cacheMap.put("audio_transcript", analysis.transcript());
            cacheMap.put("thumbnail_url", capture.getThumbnailUrl());
            cacheMap.put("entities", enrichedEntities.stream().map(e -> {
                Map<String, Object> entityMap = new HashMap<>();
                entityMap.put("title", e.title());
                entityMap.put("description", e.description() != null ? e.description() : "");
                entityMap.put("external_url", e.externalUrl() != null ? e.externalUrl() : "");
                entityMap.put("entity_type", e.entityType().name());
                entityMap.put("action_cta", e.actionCta().name());
                entityMap.put("metadata", e.metadata() != null ? e.metadata() : Map.of());
                return entityMap;
            }).toList());

            canonicalSource.setAiAnalysisCache(cacheMap);
            canonicalSourceMapper.update(canonicalSource);

            // 6.2 Update Capture
            capture.setStatus(CaptureStatus.COMPLETED);
            capture.setIntent(analysis.intent());
            capture.setCategory(analysis.category());
            capture.setSubCategory(analysis.subCategory());
            capture.setTitle(analysis.title());
            capture.setOriginalCaption(caption);
            capture.setAudioTranscript(analysis.transcript());
            capture.setNotificationCopies(analysis.notificationCopies());
            capture.setDurationMs(System.currentTimeMillis() - startTimeMs);
            capture.setVideoDurationSec(videoDurationSec);
            captureMapper.update(capture);

            // 6.3 Insert Extracted Entities
            for (AIProvider.AIEntity ae : enrichedEntities) {
                ExtractedEntity entity = new ExtractedEntity();
                entity.setId(UUID.randomUUID());
                entity.setCaptureId(captureId);
                entity.setTitle(ae.title());
                entity.setDescription(ae.description());
                entity.setExternalUrl(ae.externalUrl());
                entity.setEntityType(ae.entityType());
                entity.setActionCta(ae.actionCta());
                entity.setMetadata(ae.metadata() != null ? ae.metadata() : Map.of());
                entity.setCreatedAt(Instant.now());
                extractedEntityMapper.insert(entity);
            }

            // 6.4 Mark Ingestion Job Completed
            job.setStatus(JobStatus.COMPLETED);
            job.setLockedAt(null);
            job.setLockedBy(null);
            ingestionJobMapper.update(job);

            log.info("Successfully completed ingestion pipeline for job {} in {}ms", jobId, capture.getDurationMs());

            // 6.5 Real-Time SSE Notification Broadcast to Foreground Mobile Device
            if (sseNotificationService != null) {
                sseNotificationService.emitCaptureEvent(userId, "CAPTURE_COMPLETED", Map.of(
                        "capture_id", captureId,
                        "status", "COMPLETED",
                        "intent", analysis.intent().name(),
                        "category", analysis.category(),
                        "sub_category", analysis.subCategory() != null ? analysis.subCategory() : "",
                        "title", analysis.title() != null ? analysis.title() : "",
                        "original_caption", caption != null ? caption : "",
                        "audio_transcript", analysis.transcript(),
                        "thumbnail_url", capture.getThumbnailUrl() != null ? capture.getThumbnailUrl() : "",
                        "entities", enrichedEntities
                ));
            }

            // 6.6 Silent FCM Push Notification for Background Sync
            if (user != null && user.getFcmToken() != null && fcmService != null) {
                fcmService.sendSilentSyncNotification(user.getFcmToken(), captureId);
            }

        } catch (Exception e) {
            handleJobFailure(job, e);
        }
    }

    private void handleJobFailure(IngestionJob job, Exception e) {
        int nextAttempt = job.getAttemptCount() + 1;
        job.setAttemptCount(nextAttempt);

        log.warn("Ingestion job {} failed on attempt {}/{}: {}", job.getId(), nextAttempt, job.getMaxAttempts(), e.getMessage());

        if (nextAttempt < job.getMaxAttempts()) {
            // Requeue for exponential backoff retry
            job.setStatus(JobStatus.PENDING);
            job.setLockedAt(null);
            job.setLockedBy(null);
            ingestionJobMapper.update(job);
        } else {
            // Max attempts reached: Mark FAILED
            job.setStatus(JobStatus.FAILED);
            job.setLockedAt(null);
            job.setLockedBy(null);
            ingestionJobMapper.update(job);

            captureMapper.findById(job.getCaptureId()).ifPresent(capture -> {
                capture.setStatus(CaptureStatus.FAILED);
                captureMapper.update(capture);
            });
            log.error("Ingestion job {} exhausted max attempts and marked FAILED", job.getId());

            // Broadcast Failure Event over SSE
            if (sseNotificationService != null) {
                sseNotificationService.emitCaptureEvent(job.getUserId(), "CAPTURE_FAILED", Map.of(
                        "capture_id", job.getCaptureId(),
                        "status", "FAILED",
                        "error", e.getMessage() != null ? e.getMessage() : "Processing failed"
                ));
            }
        }
    }
}
