package com.latyr.api;

import com.google.genai.Client;
import com.google.genai.Models;
import com.google.genai.types.Content;
import com.google.genai.types.GenerateContentConfig;
import com.google.genai.types.GenerateContentResponse;
import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.GeminiAIAdapter;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.Language;
import com.latyr.api.exception.LatyrException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class GeminiAIAdapterTest {

    @Test
    @DisplayName("Google GenAI SDK: Should parse valid JSON response from Client models")
    void testAnalyzeMedia_Success() {
        Client mockClient = mock(Client.class);
        Models mockModels = mock(Models.class);
        ReflectionTestUtils.setField(mockClient, "models", mockModels);

        String validJson = """
            {
              "transcript": "5 mind bending thriller shows on Netflix including Dark",
              "intent": "WATCH",
              "category": "Entertainment",
              "suggested_collection": "Weekend Watchlist",
              "notification_copies": ["Ready to watch Dark tonight?"],
              "entities": [
                {
                  "entity_type": "TV_SHOW",
                  "title": "Dark",
                  "description": "German sci-fi time travel thriller.",
                  "external_url": "https://www.netflix.com/title/80100172",
                  "action_cta": "WATCH",
                  "metadata": { "rating": "8.7" }
                }
              ]
            }
            """;

        GenerateContentResponse mockResponse = mock(GenerateContentResponse.class);
        when(mockResponse.text()).thenReturn(validJson);
        when(mockModels.generateContent(anyString(), any(Content.class), any(GenerateContentConfig.class))).thenReturn(mockResponse);

        GeminiAIAdapter adapter = new GeminiAIAdapter(mockClient);
        AIProvider.AIAnalysisResult result = adapter.analyzeMedia("bytes".getBytes(), "audio/mp3", "Caption", Language.ENGLISH);

        assertNotNull(result);
        assertEquals(Intent.WATCH, result.intent());
        assertEquals("Entertainment", result.category());
        assertEquals(1, result.entities().size());
        assertEquals(EntityType.TV_SHOW, result.entities().get(0).entityType());
        assertEquals("Dark", result.entities().get(0).title());
        assertEquals(ActionCTA.WATCH, result.entities().get(0).actionCta());
    }

    @Test
    @DisplayName("Google GenAI SDK Error: Throws LatyrException when Client fails")
    void testAnalyzeMedia_Failure() {
        Client mockClient = mock(Client.class);
        Models mockModels = mock(Models.class);
        ReflectionTestUtils.setField(mockClient, "models", mockModels);

        when(mockModels.generateContent(anyString(), any(Content.class), any(GenerateContentConfig.class)))
                .thenThrow(new RuntimeException("API error"));

        GeminiAIAdapter adapter = new GeminiAIAdapter(mockClient);

        LatyrException ex = assertThrows(LatyrException.class, () ->
                adapter.analyzeMedia("bytes".getBytes(), "audio/mp3", "Caption", Language.ENGLISH)
        );

        assertEquals("AI_INFERENCE_FAILED", ex.getErrorCode());
    }
}
