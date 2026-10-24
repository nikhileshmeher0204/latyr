package com.latyr.api.service;

import com.latyr.api.adapter.AIProvider.AIAnalysisResult;
import com.latyr.api.adapter.AIProvider.AIEntity;
import com.latyr.api.domain.enums.*;
import java.util.*;

/** Internal checkpoint format, independent of vendor response schemas. */
public final class CaptureAnalysisCodec {
    private CaptureAnalysisCodec() {}
    public static Map<String,Object> encode(AIAnalysisResult analysis) {
        Map<String,Object> map = new LinkedHashMap<>();
        map.put("schema_version", 1); map.put("title", analysis.title()); map.put("summary", analysis.summary());
        map.put("audio_transcript", analysis.transcript());
        map.put("intent", analysis.intent() == null ? null : analysis.intent().name());
        map.put("category", analysis.category()); map.put("sub_category", analysis.subCategory());
        map.put("suggested_collection", analysis.suggestedCollection());
        map.put("notification_copies", analysis.notificationCopies() == null ? List.of() : analysis.notificationCopies());
        map.put("entities", analysis.entities() == null ? List.of() : analysis.entities().stream().map(entity -> {
            Map<String,Object> item = new LinkedHashMap<>();
            item.put("entity_type", entity.entityType().name()); item.put("title", entity.title());
            item.put("description", entity.description()); item.put("external_url", entity.externalUrl());
            item.put("action_cta", entity.actionCta().name()); item.put("metadata", entity.metadata() == null ? Map.of() : entity.metadata());
            return item;
        }).toList());
        return map;
    }
    @SuppressWarnings("unchecked")
    public static AIAnalysisResult decode(Map<String,Object> map) {
        Object version = map.get("schema_version");
        if (version != null && (!(version instanceof Number number) || number.intValue() != 1))
            throw new IllegalArgumentException("Unsupported analysis checkpoint version");
        List<AIEntity> entities = new ArrayList<>();
        if (map.get("entities") instanceof List<?> items) for (Object item : items) {
            Map<String,Object> entity = (Map<String,Object>) item;
            entities.add(new AIEntity(EntityType.valueOf(text(entity,"entity_type")), text(entity,"title"),
                text(entity,"description"), text(entity,"external_url"), ActionCTA.valueOf(text(entity,"action_cta")),
                entity.get("metadata") instanceof Map<?,?> metadata ? (Map<String,Object>) metadata : Map.of()));
        }
        List<String> copies = map.get("notification_copies") instanceof List<?> values
                ? values.stream().filter(Objects::nonNull).map(Object::toString).toList() : List.of();
        return new AIAnalysisResult(text(map,"title"), text(map,"summary"),
                map.containsKey("audio_transcript") ? text(map,"audio_transcript") : text(map,"transcript"),
                map.get("intent") == null ? null : Intent.valueOf(text(map,"intent")), text(map,"category"),
                text(map,"sub_category"), text(map,"suggested_collection"), copies, entities);
    }
    public static String text(Map<String,Object> map, String key) { return map.get(key) == null ? null : map.get(key).toString(); }
}
