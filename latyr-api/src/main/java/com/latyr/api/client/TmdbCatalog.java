package com.latyr.api.client;

import java.util.*;

/** Immutable catalogue contract; vendor JSON stays inside its integration adapter. */
public interface TmdbCatalog {
    boolean isConfigured();
    List<TmdbItem> searchMovies(String query, Integer year);
    List<TmdbItem> searchTv(String query, Integer year);
    List<TmdbItem> searchMulti(String query);
    Optional<TmdbMovieDetails> getMovieDetails(int id);
    Optional<TmdbTvDetails> getTvDetails(int id);

    record TmdbItem(
            int id,
            String title,
            String name,
            String originalTitle,
            String originalName,
            String mediaType,
            String overview,
            String posterPath,
            String backdropPath,
            double popularity,
            double voteAverage,
            int voteCount,
            String releaseDate,
            String firstAirDate,
            String originalLanguage,
            List<Integer> genreIds
    ) {
        public TmdbItem {
            genreIds = genreIds == null ? List.of() : List.copyOf(genreIds);
        }

        public String getDisplayTitle() {
            if (title != null && !title.isBlank()) return title;
            if (name != null && !name.isBlank()) return name;
            if (originalTitle != null && !originalTitle.isBlank()) return originalTitle;
            return originalName != null ? originalName : "";
        }

        public String getDisplayDate() {
            if (releaseDate != null && !releaseDate.isBlank()) return releaseDate;
            return firstAirDate != null ? firstAirDate : "";
        }
    }

    record TmdbMovieDetails(
            int id,
            String title,
            String overview,
            String posterPath,
            String backdropPath,
            Integer runtime,
            double voteAverage,
            int voteCount,
            String releaseDate,
            String tagline,
            String imdbId,
            List<TmdbGenre> genres,
            TmdbCredits credits,
            TmdbExternalIds externalIds,
            TmdbWatchProvidersResponse watchProviders
    ) {
        public TmdbMovieDetails {
            genres = genres == null ? List.of() : List.copyOf(genres);
        }

    }

    record TmdbTvDetails(
            int id,
            String name,
            String overview,
            String posterPath,
            String backdropPath,
            Integer numberOfSeasons,
            Integer numberOfEpisodes,
            double voteAverage,
            int voteCount,
            String firstAirDate,
            String status,
            String tagline,
            List<TmdbGenre> genres,
            List<TmdbNetwork> networks,
            TmdbCredits credits,
            TmdbExternalIds externalIds,
            TmdbWatchProvidersResponse watchProviders
    ) {
        public TmdbTvDetails {
            genres = genres == null ? List.of() : List.copyOf(genres);
            networks = networks == null ? List.of() : List.copyOf(networks);
        }

    }

    record TmdbWatchProvidersResponse(
            int id,
            Map<String, TmdbCountryWatchProviders> results
    ) {
        public TmdbWatchProvidersResponse {
            results = results == null ? Map.of() : Map.copyOf(results);
        }

    }

    record TmdbCountryWatchProviders(
            String link,
            List<TmdbProviderInfo> flatrate,
            List<TmdbProviderInfo> rent,
            List<TmdbProviderInfo> buy,
            List<TmdbProviderInfo> free,
            List<TmdbProviderInfo> ads
    ) {
        public TmdbCountryWatchProviders {
            flatrate = flatrate == null ? List.of() : List.copyOf(flatrate);
            rent = rent == null ? List.of() : List.copyOf(rent);
            buy = buy == null ? List.of() : List.copyOf(buy);
            free = free == null ? List.of() : List.copyOf(free);
            ads = ads == null ? List.of() : List.copyOf(ads);
        }

    }

    record TmdbProviderInfo(
            String logoPath,
            int providerId,
            String providerName,
            int displayPriority
    ) {
    }

    record TmdbGenre(
            int id,
            String name
    ) {
    }

    record TmdbNetwork(
            int id,
            String name
    ) {
    }

    record TmdbCredits(
            List<TmdbCast> cast,
            List<TmdbCrew> crew
    ) {
        public TmdbCredits {
            cast = cast == null ? List.of() : List.copyOf(cast);
            crew = crew == null ? List.of() : List.copyOf(crew);
        }

    }

    record TmdbCast(
            String name,
            String character
    ) {
    }

    record TmdbCrew(
            String name,
            String job
    ) {
    }

    record TmdbExternalIds(
            String imdbId
    ) {
    }
}
