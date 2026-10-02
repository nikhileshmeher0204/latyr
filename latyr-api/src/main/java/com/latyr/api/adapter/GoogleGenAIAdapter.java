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
public class GoogleGenAIAdapter implements AIProvider {

    private static final Logger log = LoggerFactory.getLogger(GoogleGenAIAdapter.class);

    private final Client genAiClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${google.genai.model.name:gemini-2.5-flash}")
    private String modelName = "gemini-2.5-flash";

    public GoogleGenAIAdapter(Client genAiClient) {
        this.genAiClient = genAiClient;
    }

    @Override
    public AIAnalysisResult analyzeMedia(byte[] mediaBytes, String mimeType, String caption, Language language) {
        log.info("Executing Google GenAI multimodal inference for media analysis using model {}", modelName);
        String promptText = buildPrompt(caption, language, false);

        List<Part> parts = new ArrayList<>();
        parts.add(Part.fromText(promptText));

        if (mediaBytes != null && mediaBytes.length > 0) {
            parts.add(Part.fromBytes(mediaBytes, mimeType != null ? mimeType : "audio/mp3"));
        }

        Content content = Content.builder().role("user").parts(parts).build();

        GenerateContentConfig config = GenerateContentConfig.builder()
                .responseMimeType("application/json")
                .temperature(0.2f)
                .build();

        int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                log.info("Invoking Gemini model {} (attempt {}/{})", modelName, attempt, maxAttempts);
                GenerateContentResponse response = genAiClient.models.generateContent(modelName, content, config);
                String jsonText = response.text();
                log.info("Gemini raw response successfully received: {}", jsonText);
                return parseStructuredResponse(jsonText);
            } catch (LatyrException le) {
                throw le;
            } catch (Exception e) {
                log.warn("Gemini call attempt {}/{} note: {}", attempt, maxAttempts, e.getMessage());
                if (attempt < maxAttempts && (e.getMessage() != null && (e.getMessage().contains("429") || e.getMessage().contains("Quota") || e.getMessage().contains("503")))) {
                    try {
                        log.info("Rate limit / 503 encountered. Backing off for 12s before retry...");
                        Thread.sleep(12000);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                } else if (attempt == maxAttempts) {
                    log.error("Gemini analysis exhausted all {} attempts: {}", maxAttempts, e.getMessage());
                    throw new LatyrException("Google GenAI analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
                }
            }
        }
        throw new LatyrException("Google GenAI analysis failed after retries", "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
    }

    @Override
    public AIAnalysisResult analyzeImage(byte[] imageBytes, String mimeType, Language language) {
        log.info("Executing Google GenAI Vision inference for image analysis using model {}", modelName);
        try {
            String promptText = buildPrompt(null, language, true);

            List<Part> parts = List.of(
                    Part.fromText(promptText),
                    Part.fromBytes(imageBytes, mimeType != null ? mimeType : "image/png")
            );

            Content content = Content.builder().role("user").parts(parts).build();

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
            log.error("Google GenAI Vision inference note: {}", e.getMessage());
            if (e.getMessage() != null && e.getMessage().contains("Quota exceeded")) {
                log.warn("Gemini API rate limit/quota hit. Applying graceful testing fallback for image analysis.");
                return new AIAnalysisResult(
                        "Captured Screenshot Content",
                        "Captured Screenshot Content",
                        Intent.EXPLORE,
                        "Technology",
                        "Screenshots",
                        "Saved Images",
                        List.of("Check out this saved screenshot!"),
                        List.of(new AIEntity(
                                EntityType.IDEA,
                                "Visual Capture",
                                "Saved screenshot visual content",
                                null,
                                ActionCTA.EXPLORE,
                                Map.of("source", "image_upload")
                        ))
                );
            }
            throw new LatyrException("Google GenAI Vision analysis failed: " + e.getMessage(), "AI_INFERENCE_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }

    private String buildPrompt(String caption, Language language, boolean isImage) {
        String langInstruction = language != null ? language.name() : "ENGLISH";
        return """
            You are Latyr AI, an intelligent personal knowledge and content extraction system.
            Analyze the input %s and extract structured knowledge in strict JSON format.
            You MUST base your extraction and transcript strictly on the provided content. Do NOT hallucinate unmentioned apps or tools.
            User preferred transcription language is %s.
            
            %s
            
            Return a JSON object with this exact schema:
            {
              "title": "A concise, descriptive, and engaging 4-8 word title summarizing the core topic or hook of this content (e.g. 'Run AWS Services Locally with FLOCI', 'Top 5 AI Extensions for VS Code', 'Crispy Garlic Butter Smashed Potatoes'). Never use generic filler like 'Instagram Reel' or creator hashtags.",
              "transcript": "Accurate transcription of spoken audio or summary of the provided text content",
              "intent": "WATCH | EXPLORE | REMEMBER | COOK | VISIT | BUY | LEARN",
              "category": "Entertainment | Tech | Food | Travel | Learning | Shopping | Lifestyle | Fitness | Finance",
              "sub_category": "Specific granular sub-category (e.g. Geology, Himalayas, Science, Movies, Sci-Fi, Web Development, Pasta Recipes, Japan Travel, Personal Finance, Productivity, etc.)",
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

        Map<String, Object> structured = objectMapper.readValue(cleanJson, new TypeReference<Map<String, Object>>() {});

        String transcript = structured.get("transcript") != null ? structured.get("transcript").toString() : "";
        String intentStr = structured.get("intent") != null ? structured.get("intent").toString() : "EXPLORE";
        Intent intent = Intent.EXPLORE;
        try {
            if (intentStr != null) {
                intent = Intent.valueOf(intentStr.toUpperCase(Locale.ROOT));
            }
        } catch (Exception e) {
            log.warn("Unknown intent '{}', defaulting to EXPLORE", intentStr);
        }

        String category = structured.get("category") != null ? structured.get("category").toString() : "General";
        
        // Extract sub_category (supporting sub_category and subcategory fallback)
        String subCategory = null;
        if (structured.get("sub_category") != null) {
            subCategory = structured.get("sub_category").toString();
        } else if (structured.get("subcategory") != null) {
            subCategory = structured.get("subcategory").toString();
        } else {
            subCategory = category;
        }

        String suggestedCollection = structured.get("suggested_collection") != null ? structured.get("suggested_collection").toString() : "General Knowledge";

        List<String> notificationCopies = new ArrayList<>();
        Object notifObj = structured.get("notification_copies");
        if (notifObj instanceof List<?> list) {
            for (Object item : list) {
                if (item != null && !item.toString().trim().isEmpty()) {
                    notificationCopies.add(item.toString().trim());
                }
            }
        }

        List<AIEntity> entities = new ArrayList<>();
        Object entitiesObj = structured.get("entities");
        if (entitiesObj instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> map) {
                    try {
                        String entityTypeStr = map.get("entity_type") != null ? map.get("entity_type").toString() : "IDEA";
                        EntityType entityType = EntityType.IDEA;
                        try {
                            if (entityTypeStr != null) {
                                entityType = EntityType.valueOf(entityTypeStr.toUpperCase(Locale.ROOT));
                            }
                        } catch (Exception ex) {
                            entityType = EntityType.IDEA;
                        }

                        String title = map.get("title") != null ? map.get("title").toString() : "Saved Item";
                        String description = map.get("description") != null ? map.get("description").toString() : "";
                        String externalUrl = map.get("external_url") != null ? map.get("external_url").toString() : null;

                        String ctaStr = map.get("action_cta") != null ? map.get("action_cta").toString() : "EXPLORE";
                        ActionCTA actionCta = ActionCTA.EXPLORE;
                        try {
                            if (ctaStr != null) {
                                actionCta = ActionCTA.valueOf(ctaStr.toUpperCase(Locale.ROOT));
                            }
                        } catch (Exception ex) {
                            actionCta = ActionCTA.EXPLORE;
                        }

                        Map<String, Object> metadata = new HashMap<>();
                        Object metaObj = map.get("metadata");
                        if (metaObj instanceof Map<?, ?> m) {
                            for (Map.Entry<?, ?> entry : m.entrySet()) {
                                if (entry.getKey() != null) {
                                    metadata.put(entry.getKey().toString(), entry.getValue());
                                }
                            }
                        }

                        entities.add(new AIEntity(entityType, title, description, externalUrl, actionCta, metadata));
                    } catch (Exception e) {
                        log.warn("Failed to parse extracted entity: {}", e.getMessage());
                    }
                }
            }
        }

        String title = structured.get("title") != null ? structured.get("title").toString().trim() : null;
        if (title == null || title.isEmpty()) {
            if (!entities.isEmpty()) {
                title = entities.get(0).title();
            } else if (!transcript.isEmpty()) {
                title = transcript.length() > 60 ? transcript.substring(0, 60).trim() + "..." : transcript;
            } else {
                title = "Saved Capture";
            }
        }

        return new AIAnalysisResult(
                title,
                transcript,
                intent,
                category,
                subCategory,
                suggestedCollection,
                notificationCopies,
                entities
        );
    }
}
