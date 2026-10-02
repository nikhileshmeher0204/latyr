package com.latyr.api.adapter;

import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.Language;

import java.util.List;
import java.util.Map;

public interface AIProvider {

    AIAnalysisResult analyzeMedia(byte[] mediaBytes, String mimeType, String caption, Language language);

    AIAnalysisResult analyzeImage(byte[] imageBytes, String mimeType, Language language);

    record AIAnalysisResult(
            String title,
            String transcript,
            Intent intent,
            String category,
            String subCategory,
            String suggestedCollection,
            List<String> notificationCopies,
            List<AIEntity> entities
    ) {}

    record AIEntity(
            EntityType entityType,
            String title,
            String description,
            String externalUrl,
            ActionCTA actionCta,
            Map<String, Object> metadata
    ) {}
}
