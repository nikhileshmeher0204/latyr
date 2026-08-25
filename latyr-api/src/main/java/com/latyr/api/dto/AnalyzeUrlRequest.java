package com.latyr.api.dto;

import com.latyr.api.domain.enums.Language;
import jakarta.validation.constraints.NotBlank;
import org.hibernate.validator.constraints.URL;

public record AnalyzeUrlRequest(
        @NotBlank(message = "URL cannot be blank")
        @URL(message = "Invalid URL format")
        String url,
        Language language
) {}
