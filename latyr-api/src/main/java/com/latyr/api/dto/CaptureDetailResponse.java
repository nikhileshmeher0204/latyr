package com.latyr.api.dto;

import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.SourceType;
import com.latyr.api.domain.model.Capture;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record CaptureDetailResponse(
        UUID id,
        UUID userId,
        UUID canonicalSourceId,
        SourceType sourceType,
        ContentType contentType,
        CaptureStatus status,
        Intent intent,
        String category,
        String subCategory,
        String title,
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
                capture.getSourceType(),
                capture.getContentType(),
                capture.getStatus(),
                capture.getIntent(),
                capture.getCategory(),
                capture.getSubCategory(),
                capture.getTitle(),
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
