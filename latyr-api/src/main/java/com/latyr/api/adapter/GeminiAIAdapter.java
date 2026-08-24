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

    @Value("${gemini.mock.enabled:false}")
    private boolean mockEnabled;

    private final WebClient webClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public GeminiAIAdapter(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.build();
    }

    @Override
    public AIAnalysisResult analyzeMedia(byte[] mediaBytes, String mimeType, String caption, Language language) {
        if (mockEnabled || geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            log.info("GeminiAIAdapter running in MOCK mode for media analysis");
            return createMockAnalysis(caption, language);
        }

        log.info("Calling Gemini 1.5 Flash multimodal API for media analysis");
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
        } catch (Exception e) {
            log.error("Gemini AI inference failed: {}", e.getMessage());
            throw new LatyrException("Gemini AI analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }

    @Override
    public AIAnalysisResult analyzeImage(byte[] imageBytes, String mimeType, Language language) {
        if (mockEnabled || geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            log.info("GeminiAIAdapter running in MOCK mode for image analysis");
            return createMockImageAnalysis(language);
        }

        log.info("Calling Gemini 1.5 Flash Vision API for screenshot OCR & analysis");
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
        } catch (Exception e) {
            log.error("Gemini Vision AI inference failed: {}", e.getMessage());
            throw new LatyrException("Gemini Vision analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }

    private String buildPrompt(String caption, Language language, boolean isImage) {
        String langInstruction = language != null ? language.name() : "ENGLISH";
        return """
            You are Latyr AI, an intelligent content extraction system.
            Analyze the input %s and extract structured metadata in strict JSON format.
            User preferred transcription language is %s.
            
            %s
            
            Return a JSON object with this exact schema:
            {
              "transcript": "Full transcription or OCR summary",
              "intent": "WATCH | EXPLORE | REMEMBER | COOK | VISIT | BUY | LEARN",
              "category": "Entertainment | Tech | Food | Travel | Learning | Shopping",
              "suggested_collection": "Collection title",
              "notification_copies": [
                "Catchy reminder notification copy 1",
                "Catchy reminder notification copy 2"
              ],
              "entities": [
                {
                  "entity_type": "TV_SHOW | MOVIE | BOOK | RECIPE | GITHUB_REPO | PLACE | TOOL | IDEA | QUOTE",
                  "title": "Entity Title",
                  "description": "Short 1-line description",
                  "external_url": "Direct link if mentioned or known",
                  "action_cta": "WATCH | READ | COOK | VISIT | EXPLORE | REMEMBER | OPEN_GITHUB",
                  "metadata": { "key": "value" }
                }
              ]
            }
            Do not include Markdown formatting or code fences. Return raw JSON only.
            """.formatted(
                isImage ? "image/screenshot" : "audio and caption",
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

    private AIAnalysisResult createMockAnalysis(String caption, Language language) {
        AIEntity entity = new AIEntity(
                EntityType.TV_SHOW,
                "Dark",
                "A sci-fi mystery series involving time travel in a German town.",
                "https://www.netflix.com/title/80100172",
                ActionCTA.WATCH,
                Map.of("platform", "Netflix", "release_year", 2017, "rating", 8.7)
        );

        return new AIAnalysisResult(
                "Agar aapko mind-bending suspense thriller shows pasand hain, toh Dark zaroor dekhein.",
                Intent.WATCH,
                "Entertainment",
                "Thriller Shows",
                List.of(
                        "Ready to unwind? You saved 5 mind-bending thrillers this week, including Dark.",
                        "Looking for something to watch tonight? Check out your saved thriller watchlist."
                ),
                List.of(entity)
        );
    }

    private AIAnalysisResult createMockImageAnalysis(Language language) {
        AIEntity entity = new AIEntity(
                EntityType.GITHUB_REPO,
                "latyr/latyr-api",
                "High performance Project Loom virtual-thread powered backend",
                "https://github.com/nikhileshmeher0204/latyr",
                ActionCTA.OPEN_GITHUB,
                Map.of("language", "Java", "stars", 142)
        );

        return new AIAnalysisResult(
                "Screenshot of GitHub repository latyr-api",
                Intent.EXPLORE,
                "Tech",
                "Developer Tools",
                List.of("Check out the open source repository you saved earlier."),
                List.of(entity)
        );
    }
}
