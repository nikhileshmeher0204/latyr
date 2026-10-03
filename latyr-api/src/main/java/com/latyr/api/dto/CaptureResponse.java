package com.latyr.api.dto;

import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.SourceType;
import com.latyr.api.domain.model.Capture;

import java.time.Instant;
import java.util.UUID;

public record CaptureResponse(
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
        String summary,
        String originalCaption,
        String thumbnailUrl,
        int resurfaceCount,
        Instant createdAt,
        Instant updatedAt,
        String message
) {
    public static CaptureResponse fromModel(Capture capture, String message) {
        return new CaptureResponse(
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
                capture.getSummary(),
                capture.getOriginalCaption(),
                capture.getThumbnailUrl(),
                capture.getResurfaceCount(),
                capture.getCreatedAt(),
                capture.getUpdatedAt(),
                message
        );
    }
}
