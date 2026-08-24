package com.latyr.api.service;

import com.latyr.api.domain.enums.*;
import com.latyr.api.domain.model.CanonicalSource;
import com.latyr.api.domain.model.Capture;
import com.latyr.api.domain.model.ExtractedEntity;
import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.dto.*;
import com.latyr.api.exception.ResourceNotFoundException;
import com.latyr.api.mapper.CaptureMapper;
import com.latyr.api.mapper.ExtractedEntityMapper;
import com.latyr.api.mapper.IngestionJobMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class CaptureService {

    private static final Logger log = LoggerFactory.getLogger(CaptureService.class);

    private final CaptureMapper captureMapper;
    private final ExtractedEntityMapper extractedEntityMapper;
    private final IngestionJobMapper ingestionJobMapper;
    private final SubscriptionQuotaService quotaService;
    private final UrlNormalizationService urlNormalizationService;
    private final CanonicalDeduplicationService deduplicationService;

    public CaptureService(
            CaptureMapper captureMapper,
            ExtractedEntityMapper extractedEntityMapper,
            IngestionJobMapper ingestionJobMapper,
            SubscriptionQuotaService quotaService,
            UrlNormalizationService urlNormalizationService,
            CanonicalDeduplicationService deduplicationService) {
        this.captureMapper = captureMapper;
        this.extractedEntityMapper = extractedEntityMapper;
        this.ingestionJobMapper = ingestionJobMapper;
        this.quotaService = quotaService;
        this.urlNormalizationService = urlNormalizationService;
        this.deduplicationService = deduplicationService;
    }

    @Transactional
    public CaptureResponse createUrlCapture(UUID userId, CreateCaptureRequest request) {
        // 1. Enforce monthly quota
        quotaService.verifyAndIncrementQuota(userId);

        // 2. Canonicalize URL and compute SHA-256 hash
        String canonicalHash = urlNormalizationService.getCanonicalUrlHash(request.url());
        SourceType sourceType = determineSourceType(request.url());

        // 3. Check 30-day deduplication cache
        Optional<CanonicalSource> cachedSourceOpt = deduplicationService.findCachedSource(canonicalHash);

        if (cachedSourceOpt.isPresent()) {
            // CACHE HIT: Instant completion with $0 AI cost
            CanonicalSource cachedSource = cachedSourceOpt.get();
            Capture completedCapture = buildCompletedCaptureFromCache(userId, cachedSource, ContentType.URL);
            captureMapper.insert(completedCapture);

            copyEntitiesFromCache(completedCapture.getId(), cachedSource.getAiAnalysisCache());
            log.info("Completed URL capture {} for user {} from deduplication cache", completedCapture.getId(), userId);

            return CaptureResponse.fromModel(completedCapture, "Capture processed immediately from deduplication cache.");
        }

        // CACHE MISS: Enqueue async ingestion job
        CanonicalSource canonicalSource = deduplicationService.getOrCreateCanonicalSource(canonicalHash, sourceType, request.url());

        Capture capture = new Capture();
        capture.setId(UUID.randomUUID());
        capture.setUserId(userId);
        capture.setCanonicalSourceId(canonicalSource.getId());
        capture.setContentType(ContentType.URL);
        capture.setStatus(CaptureStatus.PENDING);
        capture.setCreatedAt(Instant.now());
        capture.setUpdatedAt(Instant.now());
        captureMapper.insert(capture);

        IngestionJob job = new IngestionJob();
        job.setId(UUID.randomUUID());
        job.setCaptureId(capture.getId());
        job.setUserId(userId);
        job.setSourceType(sourceType);
        job.setPayload(Map.of("url", request.url(), "canonical_hash", canonicalHash));
        job.setStatus(JobStatus.PENDING);
        job.setAttemptCount(0);
        job.setMaxAttempts(3);
        job.setCreatedAt(Instant.now());
        job.setUpdatedAt(Instant.now());
        ingestionJobMapper.insert(job);

        log.info("Enqueued ingestion job {} for capture {} (user {})", job.getId(), capture.getId(), userId);
        return CaptureResponse.fromModel(capture, "Capture queued for asynchronous AI analysis.");
    }

    @Transactional
    public CaptureResponse createImageCapture(UUID userId, byte[] imageBytes, String originalFilename) {
        // 1. Enforce monthly quota
        quotaService.verifyAndIncrementQuota(userId);

        // 2. Compute SHA-256 byte checksum
        String imageHash = urlNormalizationService.computeSha256(imageBytes);

        // 3. Check deduplication cache
        Optional<CanonicalSource> cachedSourceOpt = deduplicationService.findCachedSource(imageHash);

        if (cachedSourceOpt.isPresent()) {
            CanonicalSource cachedSource = cachedSourceOpt.get();
            Capture completedCapture = buildCompletedCaptureFromCache(userId, cachedSource, ContentType.IMAGE);
            captureMapper.insert(completedCapture);

            copyEntitiesFromCache(completedCapture.getId(), cachedSource.getAiAnalysisCache());
            log.info("Completed image capture {} for user {} from deduplication cache", completedCapture.getId(), userId);

            return CaptureResponse.fromModel(completedCapture, "Screenshot processed immediately from deduplication cache.");
        }

        // CACHE MISS: Enqueue async image processing job
        CanonicalSource canonicalSource = deduplicationService.getOrCreateCanonicalSource(imageHash, SourceType.IMAGE, originalFilename != null ? originalFilename : "screenshot.png");

        Capture capture = new Capture();
        capture.setId(UUID.randomUUID());
        capture.setUserId(userId);
        capture.setCanonicalSourceId(canonicalSource.getId());
        capture.setContentType(ContentType.IMAGE);
        capture.setStatus(CaptureStatus.PENDING);
        capture.setCreatedAt(Instant.now());
        capture.setUpdatedAt(Instant.now());
        captureMapper.insert(capture);

        IngestionJob job = new IngestionJob();
        job.setId(UUID.randomUUID());
        job.setCaptureId(capture.getId());
        job.setUserId(userId);
        job.setSourceType(SourceType.IMAGE);
        job.setPayload(Map.of("filename", originalFilename != null ? originalFilename : "screenshot.png", "image_hash", imageHash));
        job.setStatus(JobStatus.PENDING);
        job.setAttemptCount(0);
        job.setMaxAttempts(3);
        job.setCreatedAt(Instant.now());
        job.setUpdatedAt(Instant.now());
        ingestionJobMapper.insert(job);

        log.info("Enqueued screenshot ingestion job {} for capture {} (user {})", job.getId(), capture.getId(), userId);
        return CaptureResponse.fromModel(capture, "Screenshot queued for asynchronous AI OCR and analysis.");
    }

    @Transactional(readOnly = true)
    public CaptureDetailResponse getCaptureDetail(UUID userId, UUID captureId) {
        Capture capture = captureMapper.findByIdAndUserId(captureId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Capture not found with ID: " + captureId));

        List<ExtractedEntity> entities = extractedEntityMapper.findByCaptureId(captureId);
        List<ExtractedEntityResponse> entityResponses = entities.stream()
                .map(ExtractedEntityResponse::fromModel)
                .toList();

        return CaptureDetailResponse.fromModel(capture, entityResponses);
    }

    @Transactional(readOnly = true)
    public PagedResponse<CaptureResponse> getUserCaptures(UUID userId, CaptureStatus status, String category, int page, int size) {
        int limit = Math.max(1, Math.min(100, size));
        int offset = Math.max(0, page) * limit;

        List<Capture> captures;
        long total;

        if (status != null) {
            captures = captureMapper.findByUserIdAndStatus(userId, status, limit, offset);
            total = captureMapper.countByUserIdAndStatus(userId, status);
        } else if (category != null && !category.trim().isEmpty()) {
            captures = captureMapper.findByUserIdAndCategory(userId, category.trim(), limit, offset);
            total = captureMapper.countByUserIdAndCategory(userId, category.trim());
        } else {
            captures = captureMapper.findByUserId(userId, limit, offset);
            total = captureMapper.countByUserId(userId);
        }

        List<CaptureResponse> responseList = captures.stream()
                .map(c -> CaptureResponse.fromModel(c, null))
                .toList();

        return PagedResponse.of(responseList, page, limit, total);
    }

    @Transactional
    public ExtractedEntityResponse updateEntity(UUID userId, UUID entityId, UpdateEntityRequest request) {
        ExtractedEntity entity = extractedEntityMapper.findById(entityId)
                .orElseThrow(() -> new ResourceNotFoundException("Entity not found with ID: " + entityId));

        // Verify user owns the parent capture
        captureMapper.findByIdAndUserId(entity.getCaptureId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Entity not found or unauthorized"));

        if (request.title() != null && !request.title().trim().isEmpty()) {
            entity.setTitle(request.title().trim());
        }
        if (request.description() != null) {
            entity.setDescription(request.description().trim());
        }
        if (request.externalUrl() != null) {
            entity.setExternalUrl(request.externalUrl().trim());
        }
        if (request.actionCta() != null) {
            entity.setActionCta(request.actionCta());
        }
        if (request.entityType() != null) {
            entity.setEntityType(request.entityType());
        }
        if (request.metadata() != null) {
            entity.setMetadata(request.metadata());
        }

        extractedEntityMapper.update(entity);
        log.info("User {} updated entity {}", userId, entityId);

        return ExtractedEntityResponse.fromModel(entity);
    }

    private SourceType determineSourceType(String url) {
        String lower = url.toLowerCase(Locale.ROOT);
        if (lower.contains("instagram.com") || lower.contains("instagr.am")) {
            return SourceType.INSTAGRAM_REEL;
        } else if (lower.contains("youtube.com") || lower.contains("youtu.be")) {
            return SourceType.YOUTUBE_SHORT;
        }
        return SourceType.WEB_URL;
    }

    @SuppressWarnings("unchecked")
    private Capture buildCompletedCaptureFromCache(UUID userId, CanonicalSource cachedSource, ContentType contentType) {
        Map<String, Object> cache = cachedSource.getAiAnalysisCache();

        Capture capture = new Capture();
        capture.setId(UUID.randomUUID());
        capture.setUserId(userId);
        capture.setCanonicalSourceId(cachedSource.getId());
        capture.setContentType(contentType);
        capture.setStatus(CaptureStatus.COMPLETED);

        String intentStr = (String) cache.get("intent");
        if (intentStr != null) {
            try {
                capture.setIntent(Intent.valueOf(intentStr.toUpperCase(Locale.ROOT)));
            } catch (Exception ignored) {}
        }

        capture.setCategory((String) cache.getOrDefault("category", "General"));
        capture.setOriginalCaption((String) cache.get("original_caption"));
        capture.setAudioTranscript((String) cache.get("audio_transcript"));

        Object copiesObj = cache.get("notification_copies");
        if (copiesObj instanceof List<?> copiesList) {
            List<String> copies = new ArrayList<>();
            for (Object o : copiesList) {
                if (o != null) {
                    copies.add(o.toString());
                }
            }
            capture.setNotificationCopies(copies);
        }

        capture.setCreatedAt(Instant.now());
        capture.setUpdatedAt(Instant.now());
        return capture;
    }

    @SuppressWarnings("unchecked")
    private void copyEntitiesFromCache(UUID captureId, Map<String, Object> cache) {
        Object entitiesObj = cache.get("entities");
        if (entitiesObj instanceof List<?> entitiesList) {
            for (Object item : entitiesList) {
                if (item instanceof Map<?, ?> rawMap) {
                    ExtractedEntity entity = new ExtractedEntity();
                    entity.setId(UUID.randomUUID());
                    entity.setCaptureId(captureId);

                    Object titleObj = rawMap.get("title");
                    entity.setTitle(titleObj != null ? titleObj.toString() : "Untitled Entity");

                    Object descObj = rawMap.get("description");
                    entity.setDescription(descObj != null ? descObj.toString() : null);

                    Object urlObj = rawMap.get("external_url");
                    entity.setExternalUrl(urlObj != null ? urlObj.toString() : null);

                    Object typeObj = rawMap.get("entity_type");
                    if (typeObj != null) {
                        try {
                            entity.setEntityType(EntityType.valueOf(typeObj.toString()));
                        } catch (Exception ignored) {}
                    }

                    Object ctaObj = rawMap.get("action_cta");
                    if (ctaObj != null) {
                        try {
                            entity.setActionCta(ActionCTA.valueOf(ctaObj.toString()));
                        } catch (Exception ignored) {}
                    }

                    Object metaObj = rawMap.get("metadata");
                    if (metaObj instanceof Map<?, ?> metaMap) {
                        Map<String, Object> meta = new HashMap<>();
                        for (Map.Entry<?, ?> entry : metaMap.entrySet()) {
                            if (entry.getKey() != null) {
                                meta.put(entry.getKey().toString(), entry.getValue());
                            }
                        }
                        entity.setMetadata(meta);
                    }

                    entity.setCreatedAt(Instant.now());
                    extractedEntityMapper.insert(entity);
                }
            }
        }
    }
}
