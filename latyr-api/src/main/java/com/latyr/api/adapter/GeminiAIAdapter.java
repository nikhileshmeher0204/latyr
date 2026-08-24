package com.latyr.api.adapter;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.Language;
import com.latyr.api.exception.LatyrException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.*;

@Component
public class GeminiAIAdapter implements AIProvider {

    private static final Logger log = LoggerFactory.getLogger(GeminiAIAdapter.class);
    private static final String GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

    @Value("${gemini.api.key:}")
    private String geminiApiKey;

    private final WebClient webClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public GeminiAIAdapter(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.build();
    }

    @Override
    public AIAnalysisResult analyzeMedia(byte[] mediaBytes, String mimeType, String caption, Language language) {
        if (geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            log.error("Gemini API key is not configured. Set GEMINI_API_KEY in your environment or .env file.");
            throw new LatyrException("Gemini API key is missing. Please set GEMINI_API_KEY.", "MISSING_CONFIGURATION", HttpStatus.INTERNAL_SERVER_ERROR);
        }

        log.info("Executing live Gemini 1.5 Flash multimodal API for media audio/caption analysis");
        try {
            String promptText = buildPrompt(caption, language, false);
            String base64Media = mediaBytes != null && mediaBytes.length > 0 ? Base64.getEncoder().encodeToString(mediaBytes) : null;

            Map<String, Object> requestBody = buildGeminiRequestBody(promptText, base64Media, mimeType != null ? mimeType : "audio/mp3");

            String responseJson = webClient.post()
                    .uri(GEMINI_API_BASE + "?key=" + geminiApiKey.trim())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(Duration.ofSeconds(60));

            return parseGeminiResponse(responseJson);
        } catch (LatyrException le) {
            throw le;
        } catch (Exception e) {
            log.error("Live Gemini AI inference failed: {}", e.getMessage());
            throw new LatyrException("Gemini AI analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }

    @Override
    public AIAnalysisResult analyzeImage(byte[] imageBytes, String mimeType, Language language) {
        if (geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            log.error("Gemini API key is not configured. Set GEMINI_API_KEY in your environment or .env file.");
            throw new LatyrException("Gemini API key is missing. Please set GEMINI_API_KEY.", "MISSING_CONFIGURATION", HttpStatus.INTERNAL_SERVER_ERROR);
        }

        log.info("Executing live Gemini 1.5 Flash Vision API for screenshot OCR & multimodal entity analysis");
        try {
            String promptText = buildPrompt(null, language, true);
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            Map<String, Object> requestBody = buildGeminiRequestBody(promptText, base64Image, mimeType != null ? mimeType : "image/png");

            String responseJson = webClient.post()
                    .uri(GEMINI_API_BASE + "?key=" + geminiApiKey.trim())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(Duration.ofSeconds(60));

            return parseGeminiResponse(responseJson);
        } catch (LatyrException le) {
            throw le;
        } catch (Exception e) {
            log.error("Live Gemini Vision AI inference failed: {}", e.getMessage());
            throw new LatyrException("Gemini Vision analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
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

    private Map<String, Object> buildGeminiRequestBody(String promptText, String base64Data, String mimeType) {
        List<Map<String, Object>> parts = new ArrayList<>();
        parts.add(Map.of("text", promptText));

        if (base64Data != null && !base64Data.isEmpty()) {
            parts.add(Map.of(
                    "inlineData", Map.of(
                            "mimeType", mimeType,
                            "data", base64Data
                    )
            ));
        }

        return Map.of(
                "contents", List.of(Map.of("parts", parts)),
                "generationConfig", Map.of(
                        "responseMimeType", "application/json",
                        "temperature", 0.2
                )
        );
    }

    @SuppressWarnings("unchecked")
    private AIAnalysisResult parseGeminiResponse(String rawResponse) throws Exception {
        Map<String, Object> root = objectMapper.readValue(rawResponse, new TypeReference<>() {});
        List<Map<String, Object>> candidates = (List<Map<String, Object>>) root.get("candidates");
        if (candidates == null || candidates.isEmpty()) {
            throw new IllegalStateException("No candidates returned by Gemini");
        }

        Map<String, Object> content = (Map<String, Object>) candidates.get(0).get("content");
        List<Map<String, Object>> parts = (List<Map<String, Object>>) content.get("parts");
        String text = (String) parts.get(0).get("text");

        // Parse structured JSON from model text
        Map<String, Object> structured = objectMapper.readValue(text, new TypeReference<>() {});

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
