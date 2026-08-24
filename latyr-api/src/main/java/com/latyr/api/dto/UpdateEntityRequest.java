package com.latyr.api.dto;

import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import jakarta.validation.constraints.Size;

import java.util.Map;

public record UpdateEntityRequest(
        EntityType entityType,

        @Size(max = 255, message = "Title must not exceed 255 characters")
        String title,

        String description,

        String externalUrl,

        ActionCTA actionCta,

        Map<String, Object> metadata
) {}
