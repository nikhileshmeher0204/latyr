package com.latyr.api;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.TmdbGithubEnrichmentAdapter;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class TmdbGithubEnrichmentAdapterTest {

    @Test
    @DisplayName("Enrichment: TV Show entity receives fallback poster if TMDB key is unconfigured")
    void testEnrichEntities_TvShowFallback() {
        TmdbGithubEnrichmentAdapter enricher = new TmdbGithubEnrichmentAdapter(WebClient.builder());

        AIProvider.AIEntity entity = new AIProvider.AIEntity(
                EntityType.TV_SHOW,
                "Dark",
                "A sci-fi series",
                "https://netflix.com",
                ActionCTA.WATCH,
                new HashMap<>()
        );

        List<AIProvider.AIEntity> enriched = enricher.enrichEntities(List.of(entity));

        assertNotNull(enriched);
        assertEquals(1, enriched.size());
        assertTrue(enriched.get(0).metadata().containsKey("poster_url"));
    }
}
