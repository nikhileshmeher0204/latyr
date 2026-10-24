package com.latyr.api;

import com.latyr.api.adapter.AssetStorage;
import com.latyr.api.event.AssetUploadRequestedEvent;
import com.latyr.api.mapper.CanonicalSourceMapper;
import com.latyr.api.mapper.CaptureMapper;
import com.latyr.api.domain.model.Capture;
import com.latyr.api.service.AssetStorageEventListener;
import com.latyr.api.service.SseNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AssetStorageEventListenerTest {

    private AssetStorage assetStorage;
    private CaptureMapper captureMapper;
    private CanonicalSourceMapper canonicalSourceMapper;
    private SseNotificationService sseNotificationService;
    private AssetStorageEventListener listener;

    @BeforeEach
    void setUp() {
        assetStorage = mock(AssetStorage.class);
        captureMapper = mock(CaptureMapper.class);
        canonicalSourceMapper = mock(CanonicalSourceMapper.class);
        sseNotificationService = mock(SseNotificationService.class);
        listener = new AssetStorageEventListener(assetStorage, captureMapper, canonicalSourceMapper, sseNotificationService);
    }

    @Test
    @DisplayName("Updates capture and canonical source in DB and emits SSE when asset upload succeeds")
    void handlesCaptureThumbnailUploadSuccessfully() {
        UUID captureId = UUID.randomUUID();
        UUID canonicalSourceId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        Capture capture = new Capture();
        capture.setId(captureId);
        capture.setCanonicalSourceId(canonicalSourceId);
        capture.setUserId(userId);

        when(captureMapper.findById(captureId)).thenReturn(Optional.of(capture));
        when(assetStorage.uploadAssetFromUrl(eq("https://cdn.example.com/thumb.jpg"), eq("captures/thumbnails"), eq(captureId + ".jpg")))
                .thenReturn("https://firebasestorage.googleapis.com/v0/b/bucket/o/captures%2Fthumbnails%2Fthumb.jpg?alt=media");

        AssetUploadRequestedEvent event = new AssetUploadRequestedEvent(
                "https://cdn.example.com/thumb.jpg",
                "captures/thumbnails",
                captureId + ".jpg",
                AssetUploadRequestedEvent.AssetType.CAPTURE_THUMBNAIL,
                captureId
        );

        listener.onAssetUploadRequested(event);

        verify(captureMapper).updateThumbnailUrl(eq(captureId), contains("https://firebasestorage.googleapis.com"));
        verify(canonicalSourceMapper).updateThumbnailUrl(eq(canonicalSourceId), contains("https://firebasestorage.googleapis.com"));
        verify(sseNotificationService).emitCaptureEvent(eq(userId), eq("CAPTURE_UPDATED"), any());
    }

    @Test
    @DisplayName("Skips DB update and SSE emission when asset upload returns null (e.g. local dev empty bucket)")
    void skipsDbUpdateWhenStorageReturnsNull() {
        UUID captureId = UUID.randomUUID();

        when(assetStorage.uploadAssetFromUrl(anyString(), anyString(), anyString())).thenReturn(null);

        AssetUploadRequestedEvent event = new AssetUploadRequestedEvent(
                "https://cdn.example.com/thumb.jpg",
                "captures/thumbnails",
                captureId + ".jpg",
                AssetUploadRequestedEvent.AssetType.CAPTURE_THUMBNAIL,
                captureId
        );

        listener.onAssetUploadRequested(event);

        verify(captureMapper, never()).updateThumbnailUrl(any(), any());
        verify(canonicalSourceMapper, never()).updateThumbnailUrl(any(), any());
        verify(sseNotificationService, never()).emitCaptureEvent(any(), any(), any());
    }

    @Test
    @DisplayName("Ignores event when sourceUrl is null or empty")
    void ignoresBlankOrNullSourceUrl() {
        AssetUploadRequestedEvent event = new AssetUploadRequestedEvent(
                "  ",
                "captures/thumbnails",
                "file.jpg",
                AssetUploadRequestedEvent.AssetType.CAPTURE_THUMBNAIL,
                UUID.randomUUID()
        );

        listener.onAssetUploadRequested(event);

        verifyNoInteractions(assetStorage);
        verifyNoInteractions(captureMapper);
        verifyNoInteractions(canonicalSourceMapper);
    }
}
