package com.latyr.api.dto;

import jakarta.validation.constraints.Size;

public record UpdateCollectionRequest(
        @Size(max = 120, message = "Collection name must be at most 120 characters")
        String name,

        @Size(max = 500, message = "Description must be at most 500 characters")
        String description,

        String icon,

        String colorHex,

        Boolean isPinned
) {}
