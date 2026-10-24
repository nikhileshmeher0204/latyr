package com.latyr.api.service;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import java.util.List;
import java.util.Map;

/** The same admission predicate applies to fresh analysis and reused analysis. */
public final class CaptureSuccessPolicy {
    private CaptureSuccessPolicy() {}

    public static boolean isUseful(AIProvider.AIAnalysisResult result) {
        return result != null && result.intent() != null && result.entities() != null
                && !result.entities().isEmpty() && result.entities().stream().allMatch(entity ->
                entity != null && usefulTitle(entity.title()) && entity.entityType() != null && entity.actionCta() != null);
    }

    public static boolean isUsefulCache(Map<String, Object> cache) {
        if (cache == null || !(cache.get("entities") instanceof List<?> entities) || entities.isEmpty()) return false;
        if (cache.containsKey("schema_version") && (!(cache.get("schema_version") instanceof Number version) || version.intValue() != 1)) return false;
        try {
            Intent.valueOf(String.valueOf(cache.get("intent")));
            for (Object item : entities) {
                if (!(item instanceof Map<?, ?> entity) || !usefulTitle((String) entity.get("title"))) return false;
                EntityType.valueOf(String.valueOf(entity.get("entity_type")));
                ActionCTA.valueOf(String.valueOf(entity.get("action_cta")));
            }
            return true;
        } catch (IllegalArgumentException | ClassCastException invalid) {
            return false;
        }
    }

    private static boolean usefulTitle(String title) {
        return title != null && !title.isBlank() && title.length() <= 255 && !List.of("saved item", "visual capture", "captured screenshot content")
                .contains(title.strip().toLowerCase(java.util.Locale.ROOT));
    }
}
