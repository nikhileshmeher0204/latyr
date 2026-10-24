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

        return invoke(content, config);
    }

    @Override
    public AIAnalysisResult analyzeImage(byte[] imageBytes, String mimeType, Language language) {
        if (imageBytes == null || imageBytes.length == 0)
            throw new com.latyr.api.exception.ProviderOperationException("EMPTY_IMAGE",
                    com.latyr.api.exception.ProviderOperationException.Outcome.PERMANENT);
        Content content = Content.builder().role("user").parts(List.of(
                Part.fromText(buildPrompt(null, language, true)),
                Part.fromBytes(imageBytes, mimeType != null ? mimeType : "image/png"))).build();
        GenerateContentConfig config = GenerateContentConfig.builder()
                .responseMimeType("application/json").temperature(0.2f).build();
        return invoke(content, config);
    }

    private AIAnalysisResult invoke(Content content, GenerateContentConfig config) {
        GenerateContentResponse response;
        try {
            // Durable stage recovery owns retries; one adapter invocation makes one SDK call.
            response = genAiClient.models.generateContent(modelName, content, config);
        } catch (com.google.genai.errors.ApiException rejected) {
            var outcome = rejected.code() == 429
                    ? com.latyr.api.exception.ProviderOperationException.Outcome.RETRYABLE
                    : rejected.code() >= 400 && rejected.code() < 500
                        ? com.latyr.api.exception.ProviderOperationException.Outcome.PERMANENT
                        : com.latyr.api.exception.ProviderOperationException.Outcome.AMBIGUOUS;
            String code = rejected.code() == 429 ? "AI_RATE_LIMITED"
                    : outcome == com.latyr.api.exception.ProviderOperationException.Outcome.PERMANENT ? "AI_REQUEST_REJECTED" : "AI_OUTCOME_UNKNOWN";
            throw new com.latyr.api.exception.ProviderOperationException(code, outcome);
        } catch (RuntimeException uncertain) {
            throw new com.latyr.api.exception.ProviderOperationException("AI_OUTCOME_UNKNOWN",
                    com.latyr.api.exception.ProviderOperationException.Outcome.AMBIGUOUS);
        }
        try {
            return parseStructuredResponse(response.text());
        } catch (Exception malformed) {
            throw new com.latyr.api.exception.ProviderOperationException("AI_INVALID_RESPONSE",
                    com.latyr.api.exception.ProviderOperationException.Outcome.PERMANENT);
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
              "summary": "MANDATORY: Provide an editorial 2-3 sentence summary enriched with Latyr Semantic Markup tags: (1) Highlight: Wrap exactly ONE primary standout keyword or concept in '==text==' (e.g. '==symmetric encryption=='). (2) Warning/Caveat: Wrap at most ONE critical caveat or friction point in '~text~' (e.g. '~key exchange complexity~'). (3) 3D Icons: Include 1-2 inline icons [icon:name] from: runner, lightning, rocket, lightbulb, fire, brain, sparkles, target, code, warning, bookmark, pin, calendar, globe (e.g. 'high speed [icon:runner]'). (4) Explainer Tip: Wrap key technical terms or acronyms in '[Term](tip:Brief+definition)' for interactive popover explainers (e.g. '[HTTPS](tip:Secure+hypertext+transfer+protocol)'). (5) Links: If repos, places, or dates are mentioned, use [Name](github:query), [Place](maps:query), or [Event](reminder:text). Example: 'This breakdown reveals how ==symmetric encryption== provides [icon:lightning] blazing speed while ~asymmetric key exchange~ ensures security. Learn how [HTTPS](tip:Secure+web+protocol) unifies both.' Keep it restrained, elegant, and magazine-quality. Never hallucinate unmentioned external URLs.",
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
                  "title": "Clean canonical entity title without quotes, numbering, or filler (e.g. 'Severance', 'Inception', 'Fall')",
                  "description": "Concise 1-2 sentence description or hook mentioned by creator",
                  "external_url": "Direct official or platform link if mentioned or known",
                  "action_cta": "WATCH | READ | COOK | VISIT | EXPLORE | REMEMBER | OPEN_GITHUB",
                  "metadata": {
                    "release_year": "Release year as 4-digit number or string if known/mentioned (e.g. 2022)",
                    "media_type": "movie | tv (for entertainment items)",
                    "director": "Director name if known/mentioned",
                    "lead_cast": ["Lead actor 1", "Lead actor 2"],
                    "original_language": "2-letter ISO code if known (e.g. 'en', 'ko', 'ja', 'es')",
                    "streaming_platform": "Streaming platform mentioned (e.g. 'Netflix', 'Apple TV+', 'HBO')",
                    "predicted_owner_and_repo": "Predicted 'owner/repo' if known for GITHUB_REPO (e.g. 'excalidraw/excalidraw', 'supabase/supabase', 'shadcn-ui/ui')",
                    "search_query_keywords": "Clean search query for GITHUB_REPO (e.g. 'excalidraw whiteboard')"
                  }
                }
              ]
            }
            CRITICAL EXTRACTION RULES:
            1. If the content presents a list of multiple movies, series, books, repos, or places (e.g. 'Top 5 Mind-Bending Thrillers', '3 Must-Try Tools'), you MUST extract EACH mentioned item as an individual entity in the 'entities' array. Never merge them into one.
            2. For each MOVIE or TV_SHOW entity, ensure 'title' is strictly the clean title (do NOT include '1. ', 'Number 3: ', or quotes).
            3. For GITHUB_REPO vs TOOL: If the spoken content, text, or caption mentions that a project/software/tool is open-source, starred on GitHub, hosted on GitHub, has a repo, or is an open-source library/framework/model (e.g. 'starred it on GitHub', 'just open-sourced', 'found this repo', 'on GitHub'), you MUST tag it as GITHUB_REPO, NEVER as TOOL (even if the speaker colloquially calls it a 'tool' or 'AI tool'). ONLY tag as TOOL if it is a proprietary, closed-source SaaS/commercial web application (e.g. Notion, Figma, Linear, Arc, Cursor, Slack) with no public code repository. Set 'title' strictly to the canonical project name (e.g. 'MiroFish', 'Supabase', 'Excalidraw'). Normalize speech-to-text misspellings to canonical names (e.g. 'super base' -> 'supabase', 'chad cn' -> 'shadcn') and provide 'predicted_owner_and_repo' if known.
            Do NOT wrap the JSON in Markdown code fences (no ```json ... ```). Return raw, valid JSON only. However, the string inside "summary" MUST use the requested Latyr semantic tags (==highlight==, ~wavy~, etc.).
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
        String summary = structured.get("summary") != null ? structured.get("summary").toString() : "";
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

                        String title = map.get("title") != null ? map.get("title").toString().strip() : "";
                        if (title.isBlank()) continue;
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
                summary,
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
