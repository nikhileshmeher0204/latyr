package com.latyr.api.service;

import com.latyr.api.adapter.*;
import com.latyr.api.adapter.AIProvider.AIAnalysisResult;
import com.latyr.api.adapter.AIProvider.AIEntity;
import com.latyr.api.domain.enums.*;
import com.latyr.api.domain.model.*;
import com.latyr.api.dto.ExtractedEntityResponse;
import com.latyr.api.exception.*;
import com.latyr.api.mapper.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import java.util.*;

/** External work has no DB transaction; every durable write checks execution ownership. */
@Service
public class IngestionPipelineService {
    private static final Logger log = LoggerFactory.getLogger(IngestionPipelineService.class);
    private final DurableIngestionStore store;
    private final CaptureMapper captures;
    private final CanonicalSourceMapper sources;
    private final ExtractedEntityMapper entities;
    private final ScraperProvider scraper;
    private final EphemeralMediaStreamer media;
    private final AIProvider ai;
    private final EntityEnrichmentProvider enricher;
    private final ThumbnailStorage thumbnails;
    private final CaptureQuotaLedger quota;
    private final IngestionEventOutbox events;

    public IngestionPipelineService(DurableIngestionStore store, CaptureMapper captures, CanonicalSourceMapper sources,
            ExtractedEntityMapper entities, ScraperProvider scraper, EphemeralMediaStreamer media, AIProvider ai,
            EntityEnrichmentProvider enricher, ThumbnailStorage thumbnails, CaptureQuotaLedger quota,
            IngestionEventOutbox events) {
        this.store = store; this.captures = captures; this.sources = sources; this.entities = entities;
        this.scraper = scraper; this.media = media; this.ai = ai; this.enricher = enricher;
        this.thumbnails = thumbnails; this.quota = quota; this.events = events;
    }

    public void processJob(IngestionJob job) {
        String stage = null;
        boolean sourceAvailable = false;
        long started = System.nanoTime();
        try {
            if (job.getAttemptCount() > job.getMaxAttempts()) {
                fail(job, null, false, "ATTEMPTS_EXHAUSTED", true);
                return;
            }
            store.withLease(job, () -> {
                Capture capture = capture(job);
                if (capture.getStatus() != CaptureStatus.COMPLETED) {
                    capture.setStatus(CaptureStatus.PROCESSING);
                    captures.update(capture);
                    events.append(job.getUserId(), "CAPTURE_PROCESSING", Map.of("capture_id", job.getCaptureId(), "status", "PROCESSING"));
                }
            });
            Capture capture = capture(job);
            CanonicalSource source = sources.findById(job.getCanonicalSourceId()).orElseThrow();
            Map<String,Object> analysisMap;
            boolean enrichmentOnly = Boolean.TRUE.equals(job.getPayload().get("enrichment_only"));
            if (enrichmentOnly) {
                analysisMap = existingAnalysis(capture);
            } else {
                analysisMap = store.loadCheckpoint(job, "ANALYSIS");
                if (analysisMap == null && CaptureSuccessPolicy.isUsefulCache(source.getAiAnalysisCache()))
                    analysisMap = source.getAiAnalysisCache();
            }
            if (analysisMap == null) {
                stage = "SOURCE";
                Map<String,Object> input = store.loadCheckpoint(job, stage);
                if (input == null) {
                    store.startStage(job, stage);
                    input = acquireSource(job, source);
                    store.completeStage(job, stage, input);
                }
                sourceAvailable = true;
                byte[] bytes;
                if (job.getSourceType() == SourceType.IMAGE) {
                    String base64 = CaptureAnalysisCodec.text(job.getPayload(), "image_base64");
                    if (blank(base64)) throw new ProviderOperationException("EMPTY_IMAGE", ProviderOperationException.Outcome.PERMANENT);
                    bytes = Base64.getDecoder().decode(base64);
                    if (bytes.length == 0) throw new ProviderOperationException("EMPTY_IMAGE", ProviderOperationException.Outcome.PERMANENT);
                } else {
                    stage = "MEDIA";
                    store.startStage(job, stage);
                    String audioUrl = CaptureAnalysisCodec.text(input,"audio_url");
                    bytes = media.streamMedia(audioUrl);
                    if ((bytes == null || bytes.length == 0) && blank(CaptureAnalysisCodec.text(input,"caption")))
                        throw new ProviderOperationException("NO_SOURCE_CONTENT", ProviderOperationException.Outcome.PERMANENT);
                    store.completeStage(job, stage, Map.of("has_audio", bytes != null && bytes.length > 0));
                }
                stage = "ANALYSIS";
                store.startStage(job, stage);
                AIAnalysisResult analysis = job.getSourceType() == SourceType.IMAGE
                        ? ai.analyzeImage(bytes, "image/png", Language.ORIGINAL)
                        : ai.analyzeMedia(bytes, "audio/mp3", CaptureAnalysisCodec.text(input,"caption"), Language.ORIGINAL);
                if (analysis == null) throw new ProviderOperationException("AI_INVALID_RESPONSE", ProviderOperationException.Outcome.PERMANENT);
                analysisMap = CaptureAnalysisCodec.encode(analysis);
                analysisMap.put("original_caption", input.get("caption"));
                analysisMap.put("thumbnail_url", input.get("thumbnail_url"));
                analysisMap.put("video_duration_sec", input.get("duration_sec"));
                store.completeStage(job, stage, analysisMap);
            }
            sourceAvailable = true;
            if (!CaptureSuccessPolicy.isUsefulCache(analysisMap)) {
                fail(job, null, false, "NO_USEFUL_INTENTS", true);
                return;
            }
            AIAnalysisResult analysis = CaptureAnalysisCodec.decode(analysisMap);
            Map<String,Object> core = analysisMap;
            stage = null;
            store.withLease(job, () -> publishCore(job, core, started));
            stage = "ENRICHMENT";
            Map<String,Object> enrichedMap = store.loadCheckpoint(job, stage);
            if (enrichedMap == null) {
                store.startStage(job, stage);
                List<AIEntity> enriched = enricher.enrichEntities(analysis.entities());
                AIAnalysisResult result = new AIAnalysisResult(analysis.title(), analysis.summary(), analysis.transcript(),
                        analysis.intent(), analysis.category(), analysis.subCategory(), analysis.suggestedCollection(),
                        analysis.notificationCopies(), enriched);
                if (!CaptureSuccessPolicy.isUseful(result) || enriched.size() != analysis.entities().size())
                    throw new ProviderOperationException("ENRICHMENT_UNAVAILABLE", ProviderOperationException.Outcome.RETRYABLE);
                enrichedMap = CaptureAnalysisCodec.encode(result);
                enrichedMap.put("input_entity_keys", analysis.entities().stream().map(IngestionPipelineService::entityKey).toList());
                store.completeStage(job, stage, enrichedMap);
            }
            Map<String,Object> facts = enrichedMap;
            stage = null;
            store.withLease(job, () -> { publishEnrichment(job, facts); store.complete(job); });
        } catch (IngestionLeaseLostException lost) {
            log.info("Discarded stale ingestion execution for job {}", job.getId());
        } catch (AnalysisOutcomeUnknownException ambiguous) {
            fail(job, null, false, "AI_OUTCOME_UNKNOWN", true);
        } catch (ProviderOperationException failure) {
            fail(job, stage, failure.getOutcome() == ProviderOperationException.Outcome.RETRYABLE,
                    failure.getErrorCode(), sourceAvailable);
        } catch (LatyrException failure) {
            fail(job, stage, failure.getHttpStatus().is5xxServerError(), failure.getErrorCode(), sourceAvailable);
        } catch (Exception failure) {
            log.warn("Ingestion job {} failed at {} ({})", job.getId(), stage, failure.getClass().getSimpleName());
            // An unclassified AI failure may have been accepted remotely; never replay it blindly.
            fail(job, stage, !"ANALYSIS".equals(stage),
                    "ANALYSIS".equals(stage) ? "AI_OUTCOME_UNKNOWN" : "PROCESSING_FAILED", sourceAvailable);
        }
    }

    private Map<String,Object> acquireSource(IngestionJob job, CanonicalSource source) {
        Map<String,Object> input = new LinkedHashMap<>();
        if (job.getSourceType() == SourceType.IMAGE) { input.put("caption", null); return input; }
        if (job.getSourceType() != SourceType.INSTAGRAM_REEL)
            throw new ProviderOperationException("UNSUPPORTED_SOURCE", ProviderOperationException.Outcome.UNSUPPORTED);
        ScraperProvider.ScrapedMedia scraped = scraper.extractMedia(source.getOriginalUrl());
        if (scraped == null || (blank(scraped.caption()) && blank(scraped.audioUrl())))
            throw new ProviderOperationException("NO_SOURCE_CONTENT", ProviderOperationException.Outcome.PERMANENT);
        input.put("caption", scraped.caption()); input.put("audio_url", scraped.audioUrl());
        input.put("thumbnail_url", thumbnails.uploadImageFromUrl(scraped.thumbnailUrl(), job.getCaptureId()));
        input.put("duration_sec", scraped.durationSec());
        return input;
    }

    private void publishCore(IngestionJob job, Map<String,Object> core, long started) {
        Capture capture = capture(job);
        if (capture.getStatus() == CaptureStatus.COMPLETED) return;
        AIAnalysisResult analysis = CaptureAnalysisCodec.decode(core);
        CanonicalSource source = sources.findById(job.getCanonicalSourceId()).orElseThrow();
        if (!CaptureSuccessPolicy.isUsefulCache(source.getAiAnalysisCache())) {
            source.setAiAnalysisCache(core); source.setThumbnailUrl(CaptureAnalysisCodec.text(core,"thumbnail_url"));
            sources.update(source);
        }
        capture.setStatus(CaptureStatus.COMPLETED);
        capture.setIntent(analysis.intent()); capture.setTitle(analysis.title()); capture.setSummary(analysis.summary());
        capture.setCategory(analysis.category()); capture.setSubCategory(analysis.subCategory());
        capture.setAudioTranscript(analysis.transcript()); capture.setNotificationCopies(analysis.notificationCopies());
        capture.setOriginalCaption(CaptureAnalysisCodec.text(core,"original_caption"));
        capture.setThumbnailUrl(CaptureAnalysisCodec.text(core,"thumbnail_url"));
        if (core.get("video_duration_sec") instanceof Number duration) capture.setVideoDurationSec(duration.intValue());
        capture.setDurationMs((System.nanoTime() - started) / 1_000_000);
        captures.update(capture);
        int extractionIndex = 0;
        for (AIEntity entity : analysis.entities()) {
            ExtractedEntity row = new ExtractedEntity(); row.setId(UUID.randomUUID()); row.setCaptureId(capture.getId());
            row.setExtractionIndex(extractionIndex++);
            apply(row, entity); row.setEnrichmentStatus("PENDING"); row.setNextRetryAt(null); entities.insert(row);
        }
        quota.finalizeCapture(capture.getId());
        Map<String,Object> payload = new LinkedHashMap<>(core);
        payload.put("capture_id", capture.getId()); payload.put("status", "COMPLETED");
        payload.put("source_type", capture.getSourceType());
        payload.put("entities", entities.findByCaptureId(capture.getId()).stream().map(ExtractedEntityResponse::fromModel).toList());
        events.append(job.getUserId(), "CAPTURE_COMPLETED", payload);
    }

    private void publishEnrichment(IngestionJob job, Map<String,Object> facts) {
        List<ExtractedEntity> rows = entities.findByCaptureId(job.getCaptureId());
        List<AIEntity> results = CaptureAnalysisCodec.decode(facts).entities();
        if (rows.size() != results.size() || !(facts.get("input_entity_keys") instanceof List<?> keys) || keys.size() != results.size())
            throw new ProviderOperationException("ENRICHMENT_IDENTITY_MISMATCH", ProviderOperationException.Outcome.PERMANENT);
        Map<String,Deque<ExtractedEntity>> byIdentity = new HashMap<>();
        for (ExtractedEntity row : rows) {
            String key = entityKey(new AIEntity(row.getEntityType(),row.getTitle(),row.getDescription(),row.getExternalUrl(),row.getActionCta(),row.getMetadata()));
            byIdentity.computeIfAbsent(key, ignored -> new ArrayDeque<>()).add(row);
        }
        for (int index = 0; index < rows.size(); index++) {
            Deque<ExtractedEntity> matches = byIdentity.get(keys.get(index).toString());
            if (matches == null || matches.isEmpty())
                throw new ProviderOperationException("ENRICHMENT_IDENTITY_MISMATCH", ProviderOperationException.Outcome.PERMANENT);
            ExtractedEntity row = matches.removeFirst(); apply(row, results.get(index));
            row.setEnrichmentStatus("ENRICHED"); row.setEnrichmentError(null); entities.update(row);
            events.append(job.getUserId(), "ENTITY_ENRICHED", Map.of("capture_id", job.getCaptureId(), "entity", ExtractedEntityResponse.fromModel(row)));
        }
        CanonicalSource source = sources.findById(job.getCanonicalSourceId()).orElseThrow();
        if (CaptureSuccessPolicy.isUsefulCache(source.getAiAnalysisCache())) {
            Map<String,Object> cache = new LinkedHashMap<>(source.getAiAnalysisCache());
            cache.put("entities", facts.get("entities")); cache.put("enrichment_status", "ENRICHED");
            source.setAiAnalysisCache(cache); sources.update(source);
        }
    }

    private void fail(IngestionJob job, String stage, boolean retryable, String code, boolean sourceAvailable) {
        try {
            store.withLease(job, () -> {
                if (stage != null) store.failStage(job, stage, code);
                Capture capture = capture(job);
                Map<String,Object> partial = sourceAvailable && capture.getStatus() != CaptureStatus.COMPLETED
                        ? store.loadCheckpoint(job,"ANALYSIS") : null;
                boolean terminal = store.retryOrFail(job, retryable, code);
                if (terminal && capture.getStatus() != CaptureStatus.COMPLETED) {
                    capture.setStatus(sourceAvailable ? CaptureStatus.PARTIAL : CaptureStatus.FAILED);
                    if (partial != null) {
                        capture.setTitle(CaptureAnalysisCodec.text(partial,"title"));
                        capture.setSummary(CaptureAnalysisCodec.text(partial,"summary"));
                        capture.setAudioTranscript(CaptureAnalysisCodec.text(partial,"audio_transcript"));
                        capture.setOriginalCaption(CaptureAnalysisCodec.text(partial,"original_caption"));
                    }
                    captures.update(capture); quota.releaseCapture(capture.getId());
                    events.append(job.getUserId(), sourceAvailable ? "CAPTURE_PARTIAL" : "CAPTURE_FAILED",
                            Map.of("capture_id", capture.getId(), "status", capture.getStatus().name(), "error", code));
                } else if (terminal) {
                    for (ExtractedEntity row : entities.findByCaptureId(capture.getId())) if (!"ENRICHED".equals(row.getEnrichmentStatus())) {
                        row.setEnrichmentStatus("NOT_FOUND"); row.setEnrichmentError(code); entities.update(row);
                    }
                    events.append(job.getUserId(), "ENRICHMENT_FAILED", Map.of("capture_id", capture.getId(), "error", code));
                }
            });
        } catch (IngestionLeaseLostException lost) {
            log.info("Discarded stale failure for ingestion job {}", job.getId());
        }
    }

    private Capture capture(IngestionJob job) { return captures.findById(job.getCaptureId()).orElseThrow(); }
    private static boolean blank(String value) { return value == null || value.isBlank(); }
    private static String entityKey(AIEntity value) {
        return UUID.nameUUIDFromBytes((value.entityType().name() + ":" + value.title()).getBytes(java.nio.charset.StandardCharsets.UTF_8)).toString();
    }
    private static void apply(ExtractedEntity row, AIEntity value) {
        row.setEntityType(value.entityType()); row.setTitle(value.title()); row.setDescription(value.description());
        row.setExternalUrl(value.externalUrl()); row.setActionCta(value.actionCta());
        row.setMetadata(value.metadata() == null ? Map.of() : value.metadata());
    }
    private Map<String,Object> existingAnalysis(Capture capture) {
        AIAnalysisResult result = new AIAnalysisResult(capture.getTitle(), capture.getSummary(), capture.getAudioTranscript(),
                capture.getIntent(), capture.getCategory(), capture.getSubCategory(), null, capture.getNotificationCopies(),
                entities.findByCaptureId(capture.getId()).stream().map(row -> new AIEntity(row.getEntityType(), row.getTitle(),
                        row.getDescription(), row.getExternalUrl(), row.getActionCta(), row.getMetadata())).toList());
        return CaptureAnalysisCodec.encode(result);
    }
}
