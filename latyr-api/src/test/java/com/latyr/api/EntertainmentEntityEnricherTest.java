package com.latyr.api;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.enrichment.EntertainmentEntityEnricher;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.integration.TmdbClient;
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
        TmdbClient tmdbClient = Mockito.mock(TmdbClient.class);
        EntertainmentEntityEnricher enricher = new EntertainmentEntityEnricher(tmdbClient);

        assertTrue(enricher.supports(EntityType.MOVIE));
        assertTrue(enricher.supports(EntityType.TV_SHOW));
        assertFalse(enricher.supports(EntityType.GITHUB_REPO));
        assertFalse(enricher.supports(EntityType.PLACE));
    }

    @Test
    @DisplayName("Unconfigured TMDB client gracefully applies fallback poster without exception")
    void testUnconfiguredTmdbGracefulFallback() {
        TmdbClient tmdbClient = Mockito.mock(TmdbClient.class);
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

        AIProvider.AIEntity enriched = enricher.enrich(raw);

        assertNotNull(enriched);
        assertEquals("Inception", enriched.title());
        assertNotNull(enriched.metadata().get("poster_url"));
        assertTrue(enriched.metadata().get("poster_url").toString().contains("unsplash"));
    }

    @Test
    @DisplayName("Multi-Signal Disambiguation correctly selects verified movie and formats runtime")
    void testMultiSignalDisambiguationMovie() {
        TmdbClient tmdbClient = Mockito.mock(TmdbClient.class);
        when(tmdbClient.isConfigured()).thenReturn(true);

        TmdbClient.TmdbItem candidate1 = new TmdbClient.TmdbItem();
        candidate1.id = 157336;
        candidate1.title = "Interstellar";
        candidate1.mediaType = "movie";
        candidate1.releaseDate = "2014-11-05";
        candidate1.posterPath = "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg";
        candidate1.backdropPath = "/xJHokMbljvjADYdit5fK5VQsXEG.jpg";
        candidate1.voteAverage = 8.4;
        candidate1.voteCount = 34000;
        candidate1.popularity = 120.5;
        candidate1.originalLanguage = "en";

        when(tmdbClient.searchMovies(eq("Interstellar"), any())).thenReturn(List.of(candidate1));

        TmdbClient.TmdbMovieDetails details = new TmdbClient.TmdbMovieDetails();
        details.id = 157336;
        details.title = "Interstellar";
        details.runtime = 169;
        details.voteAverage = 8.4;
        details.voteCount = 34000;
        details.tagline = "Mankind was born on Earth.";
        details.externalIds = new TmdbClient.TmdbExternalIds();
        details.externalIds.imdbId = "tt0816692";

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
        TmdbClient tmdbClient = Mockito.mock(TmdbClient.class);
        when(tmdbClient.isConfigured()).thenReturn(true);

        TmdbClient.TmdbItem tvCandidate = new TmdbClient.TmdbItem();
        tvCandidate.id = 115036;
        tvCandidate.name = "Severance";
        tvCandidate.mediaType = "tv";
        tvCandidate.firstAirDate = "2022-02-18";
        tvCandidate.posterPath = "/u3bZgnGQ9T01sWNhyveQz0wH0Hl.jpg";
        tvCandidate.voteAverage = 8.4;
        tvCandidate.voteCount = 1200;
        tvCandidate.originalLanguage = "en";

        when(tmdbClient.searchTv(eq("Severance"), any())).thenReturn(List.of(tvCandidate));

        TmdbClient.TmdbTvDetails tvDetails = new TmdbClient.TmdbTvDetails();
        tvDetails.id = 115036;
        tvDetails.name = "Severance";
        tvDetails.numberOfSeasons = 2;
        tvDetails.numberOfEpisodes = 19;
        tvDetails.voteAverage = 8.4;
        tvDetails.voteCount = 1200;
        tvDetails.externalIds = new TmdbClient.TmdbExternalIds();
        tvDetails.externalIds.imdbId = "tt11280740";

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
