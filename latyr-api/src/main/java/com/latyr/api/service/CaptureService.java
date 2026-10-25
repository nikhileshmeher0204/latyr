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
import com.latyr.api.util.UrlSourceClassifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class CaptureService {

    private final CaptureMapper captureMapper;
    private final ExtractedEntityMapper extractedEntityMapper;
    private final IngestionJobMapper ingestionJobMapper;
    private final CaptureQuotaLedger quotaLedger;
    private final UrlNormalizationService urlNormalizationService;
    private final CanonicalDeduplicationService deduplicationService;
    private final IngestionEventOutbox eventOutbox;

    public CaptureService(
            CaptureMapper captureMapper,
            ExtractedEntityMapper extractedEntityMapper,
            IngestionJobMapper ingestionJobMapper,
            CaptureQuotaLedger quotaLedger,
            UrlNormalizationService urlNormalizationService,
            CanonicalDeduplicationService deduplicationService,
            IngestionEventOutbox eventOutbox) {
        this.captureMapper = captureMapper;
        this.extractedEntityMapper = extractedEntityMapper;
        this.ingestionJobMapper = ingestionJobMapper;
        this.quotaLedger = quotaLedger;
        this.urlNormalizationService = urlNormalizationService;
        this.deduplicationService = deduplicationService;
        this.eventOutbox = eventOutbox;
    }

    @Transactional
    public CaptureResponse createUrlCapture(UUID userId, CreateCaptureRequest request) {
        String rawUrl = request.url();
        String extractedUrl = UrlSourceClassifier.extractFirstUrl(rawUrl);
        String effectiveUrl = extractedUrl != null ? extractedUrl : (rawUrl != null ? rawUrl.trim() : "");
        urlNormalizationService.validateOutboundUrl(effectiveUrl);
        String normalizedUrl = UrlSourceClassifier.normalizeUrl(effectiveUrl);
        String canonicalHash = urlNormalizationService.getCanonicalUrlHash(normalizedUrl);
        SourceType sourceType = UrlSourceClassifier.classify(effectiveUrl);

        quotaLedger.lockAdmission(userId);
        CanonicalSource source = deduplicationService.getOrCreateCanonicalSource(canonicalHash, sourceType, effectiveUrl);
        // Public analysis must be determined by the source, never a user's share caption.
        return admitCapture(userId, source, ContentType.URL, Map.of("url", effectiveUrl));
    }

    @Transactional
    public CaptureResponse createImageCapture(UUID userId, byte[] imageBytes, String originalFilename) {
        if (imageBytes == null || imageBytes.length == 0) {
            throw new com.latyr.api.exception.LatyrException("Image cannot be empty", "INVALID_IMAGE",
                    org.springframework.http.HttpStatus.BAD_REQUEST);
        }
        // Owner partition remains a fixed-length SHA-256 value accepted by the schema.
        String imageHash = urlNormalizationService.computeSha256(userId + ":" + urlNormalizationService.computeSha256(imageBytes));
        String filename = originalFilename != null ? originalFilename : "screenshot.png";
        quotaLedger.lockAdmission(userId);
        CanonicalSource source = deduplicationService.getOrCreateCanonicalSource(imageHash, SourceType.IMAGE, filename);
        return admitCapture(userId, source, ContentType.IMAGE, Map.of(
                "image_base64", Base64.getEncoder().encodeToString(imageBytes), "filename", filename));
    }

    private CaptureResponse admitCapture(UUID userId, CanonicalSource source, ContentType contentType, Map<String, Object> payload) {
        Optional<Capture> existing = captureMapper.findByUserIdAndCanonicalSourceId(userId, source.getId());
        if (existing.isPresent()) {
            return CaptureResponse.fromModel(existing.get(), "Capture already exists.");
        }
        boolean completed = CaptureSuccessPolicy.isUsefulCache(source.getAiAnalysisCache());
        Capture capture = completed ? buildCompletedCaptureFromCache(userId, source, contentType) : new Capture();
        if (!completed) {
            capture.setId(UUID.randomUUID());
            capture.setUserId(userId);
            capture.setCanonicalSourceId(source.getId());
            capture.setSourceType(source.getSourceType());
            capture.setContentType(contentType);
            capture.setStatus(CaptureStatus.PENDING);
        }
        captureMapper.insert(capture);
        quotaLedger.reserveCapture(userId, source.getId(), capture.getId());
        if (completed) {
            List<ExtractedEntityResponse> entities = copyEntitiesFromCache(capture.getId(), source.getAiAnalysisCache());
            quotaLedger.finalizeCapture(capture.getId());
            Map<String, Object> event = new HashMap<>();
            event.put("capture_id", capture.getId());
            event.put("status", "COMPLETED");
            event.put("intent", capture.getIntent().name());
            event.put("category", capture.getCategory());
            event.put("sub_category", capture.getSubCategory());
            event.put("title", capture.getTitle());
            event.put("summary", capture.getSummary());
            event.put("thumbnail_url", capture.getThumbnailUrl());
            event.put("original_caption", capture.getOriginalCaption());
            event.put("audio_transcript", capture.getAudioTranscript());
            event.put("source_type", capture.getSourceType().name());
            event.put("entities", entities);
            eventOutbox.append(userId, "CAPTURE_COMPLETED", event);
            if (!"ENRICHED".equals(source.getAiAnalysisCache().get("enrichment_status"))) {
                Map<String, Object> enrichmentPayload = new HashMap<>(payload);
                enrichmentPayload.put("enrichment_only", true);
                enqueue(capture, source, enrichmentPayload);
            }
            return CaptureResponse.fromModel(capture, "Capture processed from existing analysis.");
        }
        enqueue(capture, source, payload);
        // Only the durable poller claims work, after this transaction has committed.
        return CaptureResponse.fromModel(capture, "Capture queued for asynchronous AI analysis.");
    }

    private void enqueue(Capture capture, CanonicalSource source, Map<String, Object> payload) {
        IngestionJob job = new IngestionJob(capture.getId(), capture.getUserId(), source.getSourceType(), payload);
        job.setId(UUID.randomUUID());
        ingestionJobMapper.insert(job);
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
        return getUserCaptures(userId, status, category, null, page, size);
    }

    @Transactional(readOnly = true)
    public PagedResponse<CaptureResponse> getUserCaptures(UUID userId, CaptureStatus status, String category, String subCategory, int page, int size) {
        int limit = Math.max(1, Math.min(100, size));
        int offset = Math.max(0, page) * limit;

        List<Capture> captures;
        long total;

        if (status != null) {
            captures = captureMapper.findByUserIdAndStatus(userId, status, limit, offset);
            total = captureMapper.countByUserIdAndStatus(userId, status);
        } else if (category != null && !category.trim().isEmpty() && subCategory != null && !subCategory.trim().isEmpty()) {
            captures = captureMapper.findByUserIdAndCategoryAndSubCategory(userId, category.trim(), subCategory.trim(), limit, offset);
            total = captureMapper.countByUserIdAndCategoryAndSubCategory(userId, category.trim(), subCategory.trim());
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

    @Transactional(readOnly = true)
    public TaxonomyResponse getUserTaxonomy(UUID userId) {
        List<CaptureMapper.CategorySubCategoryCount> rows = captureMapper.selectTaxonomyCountsByUserId(userId);
        Map<String, List<TaxonomySubCategoryDto>> categoryMap = new LinkedHashMap<>();
        Map<String, Long> categoryTotals = new LinkedHashMap<>();

        for (CaptureMapper.CategorySubCategoryCount row : rows) {
            String cat = row.getCategory();
            if (cat == null || cat.isBlank()) continue;
            String sub = row.getSubCategory();
            if (sub == null || sub.isBlank()) {
                sub = cat;
            }
            categoryTotals.merge(cat, row.getCount(), Long::sum);
            categoryMap.computeIfAbsent(cat, k -> new ArrayList<>())
                    .add(new TaxonomySubCategoryDto(sub, row.getCount()));
        }

        List<TaxonomyCategoryDto> categories = new ArrayList<>();
        for (Map.Entry<String, List<TaxonomySubCategoryDto>> entry : categoryMap.entrySet()) {
            String cat = entry.getKey();
            long total = categoryTotals.getOrDefault(cat, 0L);
            List<TaxonomySubCategoryDto> sortedSubs = entry.getValue().stream()
                    .sorted((a, b) -> Long.compare(b.count(), a.count()))
                    .toList();
            categories.add(new TaxonomyCategoryDto(cat, total, sortedSubs));
        }

        categories.sort((a, b) -> Long.compare(b.count(), a.count()));

        return new TaxonomyResponse(categories);
    }

    @Transactional
    public ExtractedEntityResponse updateEntity(UUID userId, UUID entityId, UpdateEntityRequest request) {
        throw new com.latyr.api.exception.LatyrException("Capture analysis cannot be edited", "CAPTURE_IMMUTABLE",
                org.springframework.http.HttpStatus.METHOD_NOT_ALLOWED);
    }

    @SuppressWarnings("unchecked")
    private Capture buildCompletedCaptureFromCache(UUID userId, CanonicalSource cachedSource, ContentType contentType) {
        Map<String, Object> cache = cachedSource.getAiAnalysisCache();

        Capture capture = new Capture();
        capture.setId(UUID.randomUUID());
        capture.setUserId(userId);
        capture.setCanonicalSourceId(cachedSource.getId());
        capture.setSourceType(cachedSource.getSourceType());
        capture.setContentType(contentType);
        capture.setStatus(CaptureStatus.COMPLETED);

        String intentStr = (String) cache.get("intent");
        if (intentStr != null) {
            try {
                capture.setIntent(Intent.valueOf(intentStr.toUpperCase(Locale.ROOT)));
            } catch (Exception ignored) {}
        }

        capture.setCategory((String) cache.get("category"));
        capture.setSubCategory((String) cache.get("sub_category"));
        Object tagsObj = cache.get("tags");
        if (tagsObj instanceof List<?> tagsList) {
            List<String> tags = new ArrayList<>();
            for (Object o : tagsList) {
                if (o != null) tags.add(o.toString());
            }
            capture.setTags(tags);
        }
        capture.setTitle((String) cache.get("title"));
        capture.setSummary((String) cache.get("summary"));
        capture.setThumbnailUrl((String) cache.get("thumbnail_url"));
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
    private List<ExtractedEntityResponse> copyEntitiesFromCache(UUID captureId, Map<String, Object> cache) {
        List<ExtractedEntityResponse> copied = new ArrayList<>();
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
                    entity.setExtractionIndex(copied.size());
                    entity.setEnrichmentStatus("ENRICHED".equals(cache.get("enrichment_status")) ? "ENRICHED" : "PENDING");
                    extractedEntityMapper.insert(entity);
                    copied.add(ExtractedEntityResponse.fromModel(entity));
                }
            }
        }
        return copied;
    }
}
