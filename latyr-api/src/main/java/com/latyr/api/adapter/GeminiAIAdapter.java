package com.latyr.api.adapter;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.genai.Client;
import com.google.genai.types.Content;
import com.google.genai.types.GenerateContentConfig;
import com.google.genai.types.GenerateContentResponse;
import com.google.genai.types.Part;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.Language;
import com.latyr.api.exception.LatyrException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class GeminiAIAdapter implements AIProvider {

    private static final Logger log = LoggerFactory.getLogger(GeminiAIAdapter.class);

    private final Client genAiClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${vertex.ai.model.name:gemini-1.5-flash}")
    private String modelName = "gemini-1.5-flash";

    public GeminiAIAdapter(Client genAiClient) {
        this.genAiClient = genAiClient;
    }

    @Override
    public AIAnalysisResult analyzeMedia(byte[] mediaBytes, String mimeType, String caption, Language language) {
        log.info("Executing Google GenAI (Vertex AI) multimodal inference for media analysis using model {}", modelName);
        try {
            String promptText = buildPrompt(caption, language, false);

            List<Part> parts = new ArrayList<>();
            parts.add(Part.fromText(promptText));

            if (mediaBytes != null && mediaBytes.length > 0) {
                parts.add(Part.fromBytes(mediaBytes, mimeType != null ? mimeType : "audio/mp3"));
            }

            Content content = Content.builder().parts(parts).build();

            GenerateContentConfig config = GenerateContentConfig.builder()
                    .responseMimeType("application/json")
                    .temperature(0.2f)
                    .build();

            GenerateContentResponse response = genAiClient.models.generateContent(modelName, content, config);
            String jsonText = response.text();

            return parseStructuredResponse(jsonText);
        } catch (LatyrException le) {
            throw le;
        } catch (Exception e) {
            log.error("Google GenAI inference failed: {}", e.getMessage());
            throw new LatyrException("Google GenAI analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }

    @Override
    public AIAnalysisResult analyzeImage(byte[] imageBytes, String mimeType, Language language) {
        log.info("Executing Google GenAI (Vertex AI) Vision inference for image analysis using model {}", modelName);
        try {
            String promptText = buildPrompt(null, language, true);

            List<Part> parts = List.of(
                    Part.fromText(promptText),
                    Part.fromBytes(imageBytes, mimeType != null ? mimeType : "image/png")
            );

            Content content = Content.builder().parts(parts).build();

            GenerateContentConfig config = GenerateContentConfig.builder()
                    .responseMimeType("application/json")
                    .temperature(0.2f)
                    .build();

            GenerateContentResponse response = genAiClient.models.generateContent(modelName, content, config);
            String jsonText = response.text();

            return parseStructuredResponse(jsonText);
        } catch (LatyrException le) {
            throw le;
        } catch (Exception e) {
            log.error("Google GenAI Vision inference failed: {}", e.getMessage());
            throw new LatyrException("Google GenAI Vision analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }

    private String buildPrompt(String caption, Language language, boolean isImage) {
        String langInstruction = language != null ? language.name() : "ENGLISH";
        return """
            You are Latyr AI, an intelligent personal knowledge and content extraction system.
            Analyze the input %s and extract structured knowledge in strict JSON format.
            User preferred transcription language is %s.
            
            %s
            
            Return a JSON object with this exact schema:
            {
              "transcript": "Full transcription of spoken audio or complete OCR text summary",
              "intent": "WATCH | EXPLORE | REMEMBER | COOK | VISIT | BUY | LEARN",
              "category": "Entertainment | Tech | Food | Travel | Learning | Shopping",
              "suggested_collection": "Suggested collection name",
              "notification_copies": [
                "Catchy reminder notification copy 1",
                "Catchy reminder notification copy 2"
              ],
              "entities": [
                {
                  "entity_type": "TV_SHOW | MOVIE | BOOK | RECIPE | GITHUB_REPO | PLACE | TOOL | IDEA | QUOTE",
                  "title": "Entity Title",
                  "description": "Concise 1-2 sentence description",
                  "external_url": "Direct official or platform link if mentioned or known",
                  "action_cta": "WATCH | READ | COOK | VISIT | EXPLORE | REMEMBER | OPEN_GITHUB",
                  "metadata": { "key": "value" }
                }
              ]
            }
            Do not include Markdown formatting or code fences. Return raw JSON only.
            """.formatted(
                isImage ? "image/screenshot" : "audio track and caption",
                langInstruction,
                caption != null ? "Creator Caption: " + caption : ""
        );
    }

    @SuppressWarnings("unchecked")
    private AIAnalysisResult parseStructuredResponse(String jsonText) throws Exception {
        if (jsonText == null || jsonText.trim().isEmpty()) {
            throw new IllegalStateException("Google GenAI returned empty response text");
        }

        // Clean possible markdown code fence wrappers if present
        String cleanJson = jsonText.trim();
        if (cleanJson.startsWith("```json")) {
            cleanJson = cleanJson.substring(7);
        } else if (cleanJson.startsWith("```")) {
            cleanJson = cleanJson.substring(3);
        }
        if (cleanJson.endsWith("```")) {
            cleanJson = cleanJson.substring(0, cleanJson.length() - 3);
        }
        cleanJson = cleanJson.trim();

        Map<String, Object> structured = objectMapper.readValue(cleanJson, new TypeReference<>() {});

        String transcript = (String) structured.getOrDefault("transcript", "");
        String intentStr = (String) structured.getOrDefault("intent", "EXPLORE");
        Intent intent = Intent.EXPLORE;
        try {
            intent = Intent.valueOf(intentStr.toUpperCase(Locale.ROOT));
        } catch (Exception ignored) {}

        String category = (String) structured.getOrDefault("category", "General");
        String suggestedCollection = (String) structured.getOrDefault("suggested_collection", category);

        List<String> notificationCopies = new ArrayList<>();
        Object copiesObj = structured.get("notification_copies");
        if (copiesObj instanceof List<?> list) {
            for (Object o : list) {
                if (o != null) notificationCopies.add(o.toString());
            }
        }

        List<AIEntity> entities = new ArrayList<>();
        Object entitiesObj = structured.get("entities");
        if (entitiesObj instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> rawMap) {
                    Object titleObj = rawMap.get("title");
                    String title = titleObj != null ? titleObj.toString() : "Untitled Entity";
                    Object descObj = rawMap.get("description");
                    String desc = descObj != null ? descObj.toString() : null;
                    Object urlObj = rawMap.get("external_url");
                    String url = urlObj != null ? urlObj.toString() : null;

                    EntityType type = EntityType.TOOL;
                    Object typeObj = rawMap.get("entity_type");
                    if (typeObj != null) {
                        try { type = EntityType.valueOf(typeObj.toString().toUpperCase(Locale.ROOT)); } catch (Exception ignored) {}
                    }

                    ActionCTA cta = ActionCTA.EXPLORE;
                    Object ctaObj = rawMap.get("action_cta");
                    if (ctaObj != null) {
                        try { cta = ActionCTA.valueOf(ctaObj.toString().toUpperCase(Locale.ROOT)); } catch (Exception ignored) {}
                    }

                    Map<String, Object> meta = new HashMap<>();
                    Object metaObj = rawMap.get("metadata");
                    if (metaObj instanceof Map<?, ?> rawMeta) {
                        for (Map.Entry<?, ?> entry : rawMeta.entrySet()) {
                            if (entry.getKey() != null) {
                                meta.put(entry.getKey().toString(), entry.getValue());
                            }
                        }
                    }
                    entities.add(new AIEntity(type, title, desc, url, cta, meta));
                }
            }
        }

        return new AIAnalysisResult(transcript, intent, category, suggestedCollection, notificationCopies, entities);
    }
}
