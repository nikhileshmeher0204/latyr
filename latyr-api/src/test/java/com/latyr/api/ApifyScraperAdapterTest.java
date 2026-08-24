package com.latyr.api;

import com.latyr.api.adapter.ApifyScraperAdapter;
import com.latyr.api.adapter.ScraperProvider;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.reactive.function.client.WebClient;

import static org.junit.jupiter.api.Assertions.*;

class ApifyScraperAdapterTest {

    @Test
    @DisplayName("Mock Mode: Should return valid ScrapedMedia with audioUrl and caption")
    void testExtractMedia_MockMode() {
        ApifyScraperAdapter adapter = new ApifyScraperAdapter(WebClient.builder());
        ReflectionTestUtils.setField(adapter, "mockEnabled", true);

        ScraperProvider.ScrapedMedia media = adapter.extractMedia("https://www.instagram.com/reel/C8xyz123/");

        assertNotNull(media);
        assertNotNull(media.audioUrl());
        assertTrue(media.caption().contains("thriller"));
        assertEquals(45, media.durationSec());
    }
}
