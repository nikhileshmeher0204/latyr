package com.latyr.api.dto;

import com.latyr.api.domain.enums.Language;
import jakarta.validation.constraints.Size;

public record UpdatePreferencesRequest(
        @Size(max = 64, message = "Timezone must not exceed 64 characters")
        String timezone,

        Language language,

        String fcmToken
) {}
