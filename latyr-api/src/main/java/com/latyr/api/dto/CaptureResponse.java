package com.latyr.api.dto;

import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.model.Capture;

import java.time.Instant;
import java.util.UUID;

public record CaptureResponse(
        UUID id,
        UUID userId,
        UUID canonicalSourceId,
        ContentType contentType,
        CaptureStatus status,
        Intent intent,
        String category,
        String subCategory,
        String originalCaption,
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
                capture.getContentType(),
                capture.getStatus(),
                capture.getIntent(),
                capture.getCategory(),
                capture.getSubCategory(),
                capture.getOriginalCaption(),
                capture.getResurfaceCount(),
                capture.getCreatedAt(),
                capture.getUpdatedAt(),
                message
        );
    }
}
