package com.latyr.api;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.enrichment.EntertainmentEntityEnricher;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.exception.ProviderOperationException;
import com.latyr.api.client.TmdbCatalog;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

class EntertainmentEntityEnricherTest {

    @Test
    @DisplayName("Supports only MOVIE and TV_SHOW entity types")
    void testSupports() {
        TmdbCatalog tmdbClient = Mockito.mock(TmdbCatalog.class);
        EntertainmentEntityEnricher enricher = new EntertainmentEntityEnricher(tmdbClient);

        assertTrue(enricher.supports(EntityType.MOVIE));
        assertTrue(enricher.supports(EntityType.TV_SHOW));
        assertFalse(enricher.supports(EntityType.GITHUB_REPO));
        assertFalse(enricher.supports(EntityType.PLACE));
    }

    @Test
    @DisplayName("Unconfigured catalogue is a typed configuration failure, never fabricated enrichment")
    void testUnconfiguredCatalogueFailure() {
        TmdbCatalog tmdbClient = Mockito.mock(TmdbCatalog.class);
        when(tmdbClient.isConfigured()).thenReturn(false);

        EntertainmentEntityEnricher enricher = new EntertainmentEntityEnricher(tmdbClient);
        AIProvider.AIEntity raw = new AIProvider.AIEntity(
                EntityType.MOVIE,
                "Inception",
                "A dream heist movie",
                null,
                ActionCTA.WATCH,
                Map.of("release_year", 2010)
        );

        ProviderOperationException error = assertThrows(ProviderOperationException.class, () -> enricher.enrich(raw));
        assertEquals("TMDB_NOT_CONFIGURED", error.getErrorCode());
        assertEquals(ProviderOperationException.Outcome.PERMANENT, error.getOutcome());
    }

    @Test
    @DisplayName("Multi-Signal Disambiguation correctly selects verified movie and formats runtime")
    void testMultiSignalDisambiguationMovie() {
        TmdbCatalog tmdbClient = Mockito.mock(TmdbCatalog.class);
        when(tmdbClient.isConfigured()).thenReturn(true);

        TmdbCatalog.TmdbItem candidate1 = new TmdbCatalog.TmdbItem(157336, "Interstellar", null,
                null, null, "movie", null, "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
                "/xJHokMbljvjADYdit5fK5VQsXEG.jpg", 120.5, 8.4, 34000, "2014-11-05", null, "en", List.of());

        when(tmdbClient.searchMovies(eq("Interstellar"), any())).thenReturn(List.of(candidate1));

        TmdbCatalog.TmdbMovieDetails details = new TmdbCatalog.TmdbMovieDetails(157336, "Interstellar", null,
                null, null, 169, 8.4, 34000, null, "Mankind was born on Earth.", null, List.of(), null,
                new TmdbCatalog.TmdbExternalIds("tt0816692"), null);

        when(tmdbClient.getMovieDetails(157336)).thenReturn(Optional.of(details));

        EntertainmentEntityEnricher enricher = new EntertainmentEntityEnricher(tmdbClient);
        AIProvider.AIEntity raw = new AIProvider.AIEntity(
                EntityType.MOVIE,
                "Top 1: \"Interstellar\"",
                "Space travel to save humanity",
                null,
                ActionCTA.WATCH,
                Map.of("release_year", 2014, "media_type", "movie")
        );

        AIProvider.AIEntity enriched = enricher.enrich(raw);

        assertNotNull(enriched);
        assertEquals("Interstellar", enriched.title());
        assertEquals("https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", enriched.metadata().get("poster_url"));
        assertEquals(8.4, enriched.metadata().get("rating"));
        assertEquals("2h 49m", enriched.metadata().get("runtime_formatted"));
        assertEquals("https://www.imdb.com/title/tt0816692/", enriched.externalUrl());
    }

    @Test
    @DisplayName("Multi-Signal Disambiguation correctly enriches TV Series and formats season/episode counts")
    void testMultiSignalDisambiguationTvSeries() {
        TmdbCatalog tmdbClient = Mockito.mock(TmdbCatalog.class);
        when(tmdbClient.isConfigured()).thenReturn(true);

        TmdbCatalog.TmdbItem tvCandidate = new TmdbCatalog.TmdbItem(115036, null, "Severance",
                null, null, "tv", null, "/u3bZgnGQ9T01sWNhyveQz0wH0Hl.jpg", null, 0, 8.4, 1200,
                null, "2022-02-18", "en", List.of());

        when(tmdbClient.searchTv(eq("Severance"), any())).thenReturn(List.of(tvCandidate));

        TmdbCatalog.TmdbTvDetails tvDetails = new TmdbCatalog.TmdbTvDetails(115036, "Severance", null,
                null, null, 2, 19, 8.4, 1200, null, null, null, List.of(), List.of(), null,
                new TmdbCatalog.TmdbExternalIds("tt11280740"), null);

        when(tmdbClient.getTvDetails(115036)).thenReturn(Optional.of(tvDetails));

        EntertainmentEntityEnricher enricher = new EntertainmentEntityEnricher(tmdbClient);
        AIProvider.AIEntity raw = new AIProvider.AIEntity(
                EntityType.TV_SHOW,
                "Severance",
                "Work-life balance taken to the extreme",
                null,
                ActionCTA.WATCH,
                Map.of("release_year", 2022, "media_type", "tv")
        );

        AIProvider.AIEntity enriched = enricher.enrich(raw);

        assertNotNull(enriched);
        assertEquals("Severance", enriched.title());
        assertEquals("https://image.tmdb.org/t/p/w500/u3bZgnGQ9T01sWNhyveQz0wH0Hl.jpg", enriched.metadata().get("poster_url"));
        assertEquals("2 Seasons (19 Ep)", enriched.metadata().get("seasons_formatted"));
        assertEquals("https://www.imdb.com/title/tt11280740/", enriched.externalUrl());
    }
}
