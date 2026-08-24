package com.latyr.api;

import com.google.cloud.vertexai.api.Candidate;
import com.google.cloud.vertexai.api.Content;
import com.google.cloud.vertexai.api.GenerateContentResponse;
import com.google.cloud.vertexai.api.Part;
import com.google.cloud.vertexai.generativeai.GenerativeModel;
import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.GeminiAIAdapter;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.Language;
import com.latyr.api.exception.LatyrException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class GeminiAIAdapterTest {

    @Test
    @DisplayName("Vertex AI Inference: Should parse valid JSON response from GenerativeModel")
    void testAnalyzeMedia_Success() throws IOException {
        GenerativeModel mockModel = mock(GenerativeModel.class);
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

        GenerateContentResponse mockResponse = GenerateContentResponse.newBuilder()
                .addCandidates(Candidate.newBuilder()
                        .setContent(Content.newBuilder()
                                .addParts(Part.newBuilder().setText(validJson).build())
                                .build())
                        .build())
                .build();

        when(mockModel.generateContent(any(Content.class))).thenReturn(mockResponse);

        GeminiAIAdapter adapter = new GeminiAIAdapter(mockModel);
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
    @DisplayName("Vertex AI Error: Throws LatyrException when GenerativeModel fails")
    void testAnalyzeMedia_Failure() throws IOException {
        GenerativeModel mockModel = mock(GenerativeModel.class);
        when(mockModel.generateContent(any(Content.class))).thenThrow(new RuntimeException("Quota exceeded on Vertex AI"));

        GeminiAIAdapter adapter = new GeminiAIAdapter(mockModel);

        LatyrException ex = assertThrows(LatyrException.class, () ->
                adapter.analyzeMedia("bytes".getBytes(), "audio/mp3", "Caption", Language.ENGLISH)
        );

        assertEquals("AI_INFERENCE_FAILED", ex.getErrorCode());
    }
}
