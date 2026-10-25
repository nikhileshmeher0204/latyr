package com.latyr.api.dto;

import com.latyr.api.domain.model.UserCollection;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record UserCollectionResponse(
        UUID id,
        UUID userId,
        String name,
        String description,
        String icon,
        String colorHex,
        int itemCount,
        List<String> previewArtworkUrls,
        boolean isPinned,
        Instant createdAt,
        Instant updatedAt
) {
    public static UserCollectionResponse fromModel(UserCollection model) {
        return new UserCollectionResponse(
                model.getId(),
                model.getUserId(),
                model.getName(),
                model.getDescription(),
                model.getIcon(),
                model.getColorHex(),
                model.getItemCount(),
                model.getPreviewArtworkUrls() != null ? model.getPreviewArtworkUrls() : List.of(),
                model.isPinned(),
                model.getCreatedAt(),
                model.getUpdatedAt()
        );
    }
}
