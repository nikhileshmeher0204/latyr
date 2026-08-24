package com.latyr.api;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.GeminiAIAdapter;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.enums.Language;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.reactive.function.client.WebClient;

import static org.junit.jupiter.api.Assertions.*;

class GeminiAIAdapterTest {

    @Test
    @DisplayName("Mock Mode: Should extract structured analysis with Intent, entities, and notification copies")
    void testAnalyzeMedia_MockMode() {
        GeminiAIAdapter adapter = new GeminiAIAdapter(WebClient.builder());
        ReflectionTestUtils.setField(adapter, "mockEnabled", true);

        AIProvider.AIAnalysisResult result = adapter.analyzeMedia(
                "mock-bytes".getBytes(),
                "audio/mp3",
                "Top thriller shows on Netflix #dark",
                Language.HINGLISH
        );

        assertNotNull(result);
        assertEquals(Intent.WATCH, result.intent());
        assertEquals("Entertainment", result.category());
        assertFalse(result.notificationCopies().isEmpty());
        assertFalse(result.entities().isEmpty());

        AIProvider.AIEntity entity = result.entities().get(0);
        assertEquals(EntityType.TV_SHOW, entity.entityType());
        assertEquals("Dark", entity.title());
        assertEquals(ActionCTA.WATCH, entity.actionCta());
    }

    @Test
    @DisplayName("Mock Mode: Image OCR analysis returns structured tech entity")
    void testAnalyzeImage_MockMode() {
        GeminiAIAdapter adapter = new GeminiAIAdapter(WebClient.builder());
        ReflectionTestUtils.setField(adapter, "mockEnabled", true);

        AIProvider.AIAnalysisResult result = adapter.analyzeImage(
                "image-bytes".getBytes(),
                "image/png",
                Language.ENGLISH
        );

        assertNotNull(result);
        assertEquals(Intent.EXPLORE, result.intent());
        assertEquals("Tech", result.category());
        assertFalse(result.entities().isEmpty());
        assertEquals(EntityType.GITHUB_REPO, result.entities().get(0).entityType());
    }
}
