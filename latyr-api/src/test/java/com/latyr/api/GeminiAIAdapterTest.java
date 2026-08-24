package com.latyr.api;

import com.latyr.api.adapter.GeminiAIAdapter;
import com.latyr.api.domain.enums.Language;
import com.latyr.api.exception.LatyrException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.reactive.function.client.WebClient;

import static org.junit.jupiter.api.Assertions.*;

class GeminiAIAdapterTest {

    @Test
    @DisplayName("Configuration check: Should throw LatyrException if GEMINI_API_KEY is missing for media analysis")
    void testAnalyzeMedia_MissingKey() {
        GeminiAIAdapter adapter = new GeminiAIAdapter(WebClient.builder());
        ReflectionTestUtils.setField(adapter, "geminiApiKey", "");

        LatyrException ex = assertThrows(LatyrException.class, () ->
                adapter.analyzeMedia("bytes".getBytes(), "audio/mp3", "Caption", Language.ENGLISH)
        );

        assertEquals("MISSING_CONFIGURATION", ex.getErrorCode());
    }

    @Test
    @DisplayName("Configuration check: Should throw LatyrException if GEMINI_API_KEY is missing for image analysis")
    void testAnalyzeImage_MissingKey() {
        GeminiAIAdapter adapter = new GeminiAIAdapter(WebClient.builder());
        ReflectionTestUtils.setField(adapter, "geminiApiKey", "");

        LatyrException ex = assertThrows(LatyrException.class, () ->
                adapter.analyzeImage("bytes".getBytes(), "image/png", Language.ENGLISH)
        );

        assertEquals("MISSING_CONFIGURATION", ex.getErrorCode());
    }
}
