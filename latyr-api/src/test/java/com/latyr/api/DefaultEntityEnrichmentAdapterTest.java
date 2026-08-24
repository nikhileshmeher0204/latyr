package com.latyr.api;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.DefaultEntityEnrichmentAdapter;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class DefaultEntityEnrichmentAdapterTest {

    @Test
    @DisplayName("Entity Normalization: Movie entity receives default poster fallback if missing")
    void testNormalizeEntertainmentEntity() {
        DefaultEntityEnrichmentAdapter adapter = new DefaultEntityEnrichmentAdapter();
        AIProvider.AIEntity movie = new AIProvider.AIEntity(
                EntityType.MOVIE,
                "Inception",
                "Mind-bending dream thriller.",
                "https://netflix.com/title/1234",
                ActionCTA.WATCH,
                Map.of("rating", 8.8)
        );

        List<AIProvider.AIEntity> result = adapter.enrichEntities(List.of(movie));

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Inception", result.get(0).title());
        assertNotNull(result.get(0).metadata().get("poster_url"));
    }

    @Test
    @DisplayName("Entity Normalization: GitHub entity formats repository URL from title if missing")
    void testNormalizeGithubEntity() {
        DefaultEntityEnrichmentAdapter adapter = new DefaultEntityEnrichmentAdapter();
        AIProvider.AIEntity repo = new AIProvider.AIEntity(
                EntityType.GITHUB_REPO,
                "flutter/flutter",
                "Flutter SDK repository",
                null,
                ActionCTA.OPEN_GITHUB,
                Map.of("language", "Dart")
        );

        List<AIProvider.AIEntity> result = adapter.enrichEntities(List.of(repo));

        assertNotNull(result);
        assertEquals("https://github.com/flutter/flutter", result.get(0).externalUrl());
    }
}
