package com.latyr.api.dto;

import com.latyr.api.domain.enums.ContentType;
import jakarta.validation.constraints.NotBlank;
import org.hibernate.validator.constraints.URL;

public record CreateCaptureRequest(
        @NotBlank(message = "URL is required")
        @URL(message = "A valid URL format is required")
        String url,

        ContentType contentType
) {
    public CreateCaptureRequest {
        if (contentType == null) {
            contentType = ContentType.URL;
        }
    }
}
