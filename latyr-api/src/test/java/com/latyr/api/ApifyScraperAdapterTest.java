package com.latyr.api;

import com.latyr.api.adapter.ApifyScraperAdapter;
import com.latyr.api.exception.LatyrException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.reactive.function.client.WebClient;

import static org.junit.jupiter.api.Assertions.*;

class ApifyScraperAdapterTest {

    @Test
    @DisplayName("Configuration check: Should throw LatyrException if APIFY_API_TOKEN is missing")
    void testExtractMedia_MissingToken() {
        ApifyScraperAdapter adapter = new ApifyScraperAdapter(WebClient.builder(), 1);
        ReflectionTestUtils.setField(adapter, "apiToken", "");

        LatyrException ex = assertThrows(LatyrException.class, () ->
                adapter.extractMedia("https://www.instagram.com/reel/C8xyz123/")
        );

        assertEquals("MISSING_CONFIGURATION", ex.getErrorCode());
    }
}
