package com.latyr.api.service;

import com.latyr.api.adapter.AssetStorage;
import com.latyr.api.event.AssetUploadRequestedEvent;
import com.latyr.api.mapper.CanonicalSourceMapper;
import com.latyr.api.mapper.CaptureMapper;
import com.latyr.api.domain.model.Capture;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Reusable asynchronous listener for asset upload events.
 * Executes on virtual threads to avoid blocking caller threads or DB transactions.
 */
@Component
public class AssetStorageEventListener {

    private static final Logger log = LoggerFactory.getLogger(AssetStorageEventListener.class);

    private final AssetStorage assetStorage;
    private final CaptureMapper captureMapper;
    private final CanonicalSourceMapper canonicalSourceMapper;
    private final SseNotificationService sseNotificationService;

    public AssetStorageEventListener(
            AssetStorage assetStorage,
            CaptureMapper captureMapper,
            CanonicalSourceMapper canonicalSourceMapper,
            SseNotificationService sseNotificationService) {
        this.assetStorage = assetStorage;
        this.captureMapper = captureMapper;
        this.canonicalSourceMapper = canonicalSourceMapper;
        this.sseNotificationService = sseNotificationService;
    }

    @Async("virtualThreadExecutor")
    @EventListener
    public void onAssetUploadRequested(AssetUploadRequestedEvent event) {
        if (event == null || event.sourceUrl() == null || event.sourceUrl().isBlank()) {
            return;
        }

        log.info("Processing asset upload event for {} (ref: {}): {}/{}",
                event.assetType(), event.referenceId(), event.targetFolder(), event.fileName());

        String permanentUrl = assetStorage.uploadAssetFromUrl(
                event.sourceUrl(), event.targetFolder(), event.fileName());

        if (permanentUrl == null || permanentUrl.isBlank() || permanentUrl.equals(event.sourceUrl())) {
            log.debug("No permanent storage URL generated for {} (ref: {}); keeping initial URL",
                    event.assetType(), event.referenceId());
            return;
        }

        switch (event.assetType()) {
            case CAPTURE_THUMBNAIL -> {
                captureMapper.updateThumbnailUrl(event.referenceId(), permanentUrl);
                captureMapper.findById(event.referenceId()).ifPresent(capture -> {
                    if (capture.getCanonicalSourceId() != null) {
                        canonicalSourceMapper.updateThumbnailUrl(capture.getCanonicalSourceId(), permanentUrl);
                    }
                    sseNotificationService.emitCaptureEvent(capture.getUserId(), "CAPTURE_UPDATED",
                            Map.of("capture_id", capture.getId().toString(), "thumbnail_url", permanentUrl));
                });
                log.info("Updated persistent thumbnail URL in DB for capture {}: {}", event.referenceId(), permanentUrl);
            }
            case COLLECTION_COVER -> {
                log.info("Collection cover uploaded for collection {}: {}", event.referenceId(), permanentUrl);
            }
            case USER_AVATAR -> {
                log.info("User avatar uploaded for user {}: {}", event.referenceId(), permanentUrl);
            }
        }
    }
}
