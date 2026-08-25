package com.latyr.api.dto;

import com.latyr.api.domain.enums.Language;
import jakarta.validation.constraints.NotBlank;

public record AnalyzeRawRequest(
        @NotBlank(message = "Text/caption cannot be blank")
        String caption,
        Language language
) {}
