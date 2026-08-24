package com.latyr.api.dto;

import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.model.Capture;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record CaptureDetailResponse(
        UUID id,
        UUID userId,
        UUID canonicalSourceId,
        ContentType contentType,
        CaptureStatus status,
        Intent intent,
        String category,
        String originalCaption,
        String audioTranscript,
        List<String> notificationCopies,
        int resurfaceCount,
        Long durationMs,
        Integer videoDurationSec,
        List<ExtractedEntityResponse> entities,
        Instant createdAt,
        Instant updatedAt
) {
    public static CaptureDetailResponse fromModel(Capture capture, List<ExtractedEntityResponse> entities) {
        return new CaptureDetailResponse(
                capture.getId(),
                capture.getUserId(),
                capture.getCanonicalSourceId(),
                capture.getContentType(),
                capture.getStatus(),
                capture.getIntent(),
                capture.getCategory(),
                capture.getOriginalCaption(),
                capture.getAudioTranscript(),
                capture.getNotificationCopies(),
                capture.getResurfaceCount(),
                capture.getDurationMs(),
                capture.getVideoDurationSec(),
                entities,
                capture.getCreatedAt(),
                capture.getUpdatedAt()
        );
    }
}
