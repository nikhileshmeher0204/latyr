package com.latyr.api.integration;

import com.latyr.api.client.TmdbCatalog;
import com.latyr.api.exception.ProviderOperationException;
import static com.latyr.api.exception.ProviderOperationException.Outcome.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.*;

/**
 * High-performance, virtual-thread friendly TMDB (The Movie Database) API client.
 * Read failures are classified so durable stages can retry without inventing a match.
 */
@Component
public class TmdbClient implements TmdbCatalog {

    private static final Logger log = LoggerFactory.getLogger(TmdbClient.class);

    private final String apiKey;
    private final String baseUrl;
    private final Duration connectTimeout;
    private final Duration readTimeout;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public TmdbClient(
            @Value("${latyr.enrichment.tmdb.api-key:}") String apiKey,
            @Value("${latyr.enrichment.tmdb.base-url:https://api.themoviedb.org/3}") String baseUrl,
            @Value("${latyr.enrichment.tmdb.connect-timeout-ms:1500}") int connectTimeoutMs,
            @Value("${latyr.enrichment.tmdb.read-timeout-ms:1500}") int readTimeoutMs) {
        this.apiKey = apiKey != null ? apiKey.trim() : "";
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        this.connectTimeout = Duration.ofMillis(connectTimeoutMs);
        this.readTimeout = Duration.ofMillis(readTimeoutMs);

        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(this.connectTimeout)
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();

        this.objectMapper = new ObjectMapper()
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    }

    public boolean isConfigured() {
        return !apiKey.isBlank();
    }

    /**
     * Search movies with optional primary release year filter.
     */
    public List<TmdbCatalog.TmdbItem> searchMovies(String query, Integer year) {
        if (!isConfigured()) throw new ProviderOperationException("TMDB_NOT_CONFIGURED", PERMANENT);
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }

        StringBuilder url = new StringBuilder(baseUrl)
                .append("/search/movie?query=")
                .append(encode(query))
                .append("&include_adult=false");

        if (year != null && year > 1900 && year < 2100) {
            url.append("&primary_release_year=").append(year);
        }

        return executeSearch(url.toString(), "movie");
    }

    /**
     * Search TV shows with optional first air date year filter.
     */
    public List<TmdbCatalog.TmdbItem> searchTv(String query, Integer year) {
        if (!isConfigured()) throw new ProviderOperationException("TMDB_NOT_CONFIGURED", PERMANENT);
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }

        StringBuilder url = new StringBuilder(baseUrl)
                .append("/search/tv?query=")
                .append(encode(query))
                .append("&include_adult=false");

        if (year != null && year > 1900 && year < 2100) {
            url.append("&first_air_date_year=").append(year);
        }

        return executeSearch(url.toString(), "tv");
    }

    /**
     * Multi-search across movies and TV series.
     */
    public List<TmdbCatalog.TmdbItem> searchMulti(String query) {
        if (!isConfigured()) throw new ProviderOperationException("TMDB_NOT_CONFIGURED", PERMANENT);
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }

        String url = baseUrl + "/search/multi?query=" + encode(query) + "&include_adult=false";
        return executeSearch(url, null);
    }

    /**
     * Get detailed movie information including runtime, IMDb ID, and credits.
     */
    public Optional<TmdbCatalog.TmdbMovieDetails> getMovieDetails(int movieId) {
        if (!isConfigured()) throw new ProviderOperationException("TMDB_NOT_CONFIGURED", PERMANENT);

        String url = baseUrl + "/movie/" + movieId + "?append_to_response=credits,external_ids,watch/providers";
        try {
            String json = executeGet(url);
            if (json == null) return Optional.empty();
            TmdbMovieDetails raw = objectMapper.readValue(json, TmdbMovieDetails.class);
            if (raw == null || raw.id != movieId) throw new ProviderOperationException("TMDB_INVALID_RESPONSE", RETRYABLE);
            return Optional.of(toCatalog(raw));
        } catch (ProviderOperationException failure) {
            throw failure;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new ProviderOperationException("TMDB_INTERRUPTED", RETRYABLE);
        } catch (Exception failure) {
            throw new ProviderOperationException("TMDB_UNAVAILABLE", RETRYABLE);
        }
    }

    /**
     * Get detailed TV series information including seasons, episodes, networks, and credits.
     */
    public Optional<TmdbCatalog.TmdbTvDetails> getTvDetails(int tvId) {
        if (!isConfigured()) throw new ProviderOperationException("TMDB_NOT_CONFIGURED", PERMANENT);

        String url = baseUrl + "/tv/" + tvId + "?append_to_response=credits,external_ids,watch/providers";
        try {
            String json = executeGet(url);
            if (json == null) return Optional.empty();
            TmdbTvDetails raw = objectMapper.readValue(json, TmdbTvDetails.class);
            if (raw == null || raw.id != tvId) throw new ProviderOperationException("TMDB_INVALID_RESPONSE", RETRYABLE);
            return Optional.of(toCatalog(raw));
        } catch (ProviderOperationException failure) {
            throw failure;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new ProviderOperationException("TMDB_INTERRUPTED", RETRYABLE);
        } catch (Exception failure) {
            throw new ProviderOperationException("TMDB_UNAVAILABLE", RETRYABLE);
        }
    }

    private List<TmdbCatalog.TmdbItem> executeSearch(String rawUrl, String defaultMediaType) {
        try {
            String json = executeGet(rawUrl);
            if (json == null) return Collections.emptyList();

            TmdbSearchResponse response = objectMapper.readValue(json, TmdbSearchResponse.class);
            if (response == null || response.results == null) {
                throw new ProviderOperationException("TMDB_INVALID_RESPONSE", RETRYABLE);
            }

            for (TmdbItem item : response.results) {
                if (item.mediaType == null && defaultMediaType != null) {
                    item.mediaType = defaultMediaType;
                }
            }
            return response.results.stream().filter(Objects::nonNull)
                    .filter(item -> item.id > 0 && ("movie".equals(item.mediaType) || "tv".equals(item.mediaType)))
                    .map(TmdbClient::toCatalog).toList();
        } catch (ProviderOperationException failure) {
            throw failure;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new ProviderOperationException("TMDB_INTERRUPTED", RETRYABLE);
        } catch (Exception failure) {
            throw new ProviderOperationException("TMDB_UNAVAILABLE", RETRYABLE);
        }
    }

    private String executeGet(String targetUrl) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .timeout(readTimeout)
                .header("Accept", "application/json");

        String finalUrl = targetUrl;
        if (apiKey.startsWith("eyJ")) {
            // v4 JWT Bearer Token
            builder.header("Authorization", "Bearer " + apiKey);
        } else {
            // v3 API Key query param
            String separator = targetUrl.contains("?") ? "&" : "?";
            finalUrl = targetUrl + separator + "api_key=" + apiKey;
        }

        HttpRequest request = builder.uri(URI.create(finalUrl)).GET().build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        int status = response.statusCode();
        if (status == 200) {
            return response.body();
        } else if (status == 404) {
            return null;
        }
        throw new ProviderOperationException("TMDB_HTTP_" + status,
                status == 429 || status >= 500 ? RETRYABLE : PERMANENT);
    }

    private String encode(String text) {
        return URLEncoder.encode(text, StandardCharsets.UTF_8);
    }

    private static TmdbCatalog.TmdbItem toCatalog(TmdbItem raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbItem(
            raw.id,
            raw.title,
            raw.name,
            raw.originalTitle,
            raw.originalName,
            raw.mediaType,
            raw.overview,
            raw.posterPath,
            raw.backdropPath,
            raw.popularity,
            raw.voteAverage,
            raw.voteCount,
            raw.releaseDate,
            raw.firstAirDate,
            raw.originalLanguage,
            raw.genreIds);
    }

    private static TmdbCatalog.TmdbMovieDetails toCatalog(TmdbMovieDetails raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbMovieDetails(
            raw.id,
            raw.title,
            raw.overview,
            raw.posterPath,
            raw.backdropPath,
            raw.runtime,
            raw.voteAverage,
            raw.voteCount,
            raw.releaseDate,
            raw.tagline,
            raw.imdbId,
            raw.genres == null ? List.of() : raw.genres.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            toCatalog(raw.credits),
            toCatalog(raw.externalIds),
            toCatalog(raw.watchProviders));
    }

    private static TmdbCatalog.TmdbTvDetails toCatalog(TmdbTvDetails raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbTvDetails(
            raw.id,
            raw.name,
            raw.overview,
            raw.posterPath,
            raw.backdropPath,
            raw.numberOfSeasons,
            raw.numberOfEpisodes,
            raw.voteAverage,
            raw.voteCount,
            raw.firstAirDate,
            raw.status,
            raw.tagline,
            raw.genres == null ? List.of() : raw.genres.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            raw.networks == null ? List.of() : raw.networks.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            toCatalog(raw.credits),
            toCatalog(raw.externalIds),
            toCatalog(raw.watchProviders));
    }

    private static TmdbCatalog.TmdbWatchProvidersResponse toCatalog(TmdbWatchProvidersResponse raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbWatchProvidersResponse(
            raw.id,
            raw.results == null ? Map.of() : raw.results.entrySet().stream().filter(e -> e.getValue() != null).collect(java.util.stream.Collectors.toMap(Map.Entry::getKey, e -> toCatalog(e.getValue()))));
    }

    private static TmdbCatalog.TmdbCountryWatchProviders toCatalog(TmdbCountryWatchProviders raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbCountryWatchProviders(
            raw.link,
            raw.flatrate == null ? List.of() : raw.flatrate.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            raw.rent == null ? List.of() : raw.rent.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            raw.buy == null ? List.of() : raw.buy.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            raw.free == null ? List.of() : raw.free.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            raw.ads == null ? List.of() : raw.ads.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList());
    }

    private static TmdbCatalog.TmdbProviderInfo toCatalog(TmdbProviderInfo raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbProviderInfo(
            raw.logoPath,
            raw.providerId,
            raw.providerName,
            raw.displayPriority);
    }

    private static TmdbCatalog.TmdbGenre toCatalog(TmdbGenre raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbGenre(
            raw.id,
            raw.name);
    }

    private static TmdbCatalog.TmdbNetwork toCatalog(TmdbNetwork raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbNetwork(
            raw.id,
            raw.name);
    }

    private static TmdbCatalog.TmdbCredits toCatalog(TmdbCredits raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbCredits(
            raw.cast == null ? List.of() : raw.cast.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList(),
            raw.crew == null ? List.of() : raw.crew.stream().filter(Objects::nonNull).map(TmdbClient::toCatalog).toList());
    }

    private static TmdbCatalog.TmdbCast toCatalog(TmdbCast raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbCast(
            raw.name,
            raw.character);
    }

    private static TmdbCatalog.TmdbCrew toCatalog(TmdbCrew raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbCrew(
            raw.name,
            raw.job);
    }

    private static TmdbCatalog.TmdbExternalIds toCatalog(TmdbExternalIds raw) {
        if (raw == null) return null;
        return new TmdbCatalog.TmdbExternalIds(
            raw.imdbId);
    }

    // --- TMDB Payloads ---

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbSearchResponse {
        public List<TmdbItem> results;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbItem {
        public int id;
        public String title;
        public String name;
        @JsonProperty("original_title") public String originalTitle;
        @JsonProperty("original_name") public String originalName;
        @JsonProperty("media_type") public String mediaType;
        public String overview;
        @JsonProperty("poster_path") public String posterPath;
        @JsonProperty("backdrop_path") public String backdropPath;
        public double popularity;
        @JsonProperty("vote_average") public double voteAverage;
        @JsonProperty("vote_count") public int voteCount;
        @JsonProperty("release_date") public String releaseDate;
        @JsonProperty("first_air_date") public String firstAirDate;
        @JsonProperty("original_language") public String originalLanguage;
        @JsonProperty("genre_ids") public List<Integer> genreIds = new ArrayList<>();

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

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbMovieDetails {
        public int id;
        public String title;
        public String overview;
        @JsonProperty("poster_path") public String posterPath;
        @JsonProperty("backdrop_path") public String backdropPath;
        public Integer runtime;
        @JsonProperty("vote_average") public double voteAverage;
        @JsonProperty("vote_count") public int voteCount;
        @JsonProperty("release_date") public String releaseDate;
        public String tagline;
        @JsonProperty("imdb_id") public String imdbId;
        public List<TmdbGenre> genres = new ArrayList<>();
        public TmdbCredits credits;
        @JsonProperty("external_ids") public TmdbExternalIds externalIds;
        @JsonProperty("watch/providers") public TmdbWatchProvidersResponse watchProviders;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbTvDetails {
        public int id;
        public String name;
        public String overview;
        @JsonProperty("poster_path") public String posterPath;
        @JsonProperty("backdrop_path") public String backdropPath;
        @JsonProperty("number_of_seasons") public Integer numberOfSeasons;
        @JsonProperty("number_of_episodes") public Integer numberOfEpisodes;
        @JsonProperty("vote_average") public double voteAverage;
        @JsonProperty("vote_count") public int voteCount;
        @JsonProperty("first_air_date") public String firstAirDate;
        public String status;
        public String tagline;
        public List<TmdbGenre> genres = new ArrayList<>();
        public List<TmdbNetwork> networks = new ArrayList<>();
        public TmdbCredits credits;
        @JsonProperty("external_ids") public TmdbExternalIds externalIds;
        @JsonProperty("watch/providers") public TmdbWatchProvidersResponse watchProviders;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbWatchProvidersResponse {
        public int id;
        public Map<String, TmdbCountryWatchProviders> results = new HashMap<>();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbCountryWatchProviders {
        public String link;
        public List<TmdbProviderInfo> flatrate = new ArrayList<>();
        public List<TmdbProviderInfo> rent = new ArrayList<>();
        public List<TmdbProviderInfo> buy = new ArrayList<>();
        public List<TmdbProviderInfo> free = new ArrayList<>();
        public List<TmdbProviderInfo> ads = new ArrayList<>();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbProviderInfo {
        @JsonProperty("logo_path") public String logoPath;
        @JsonProperty("provider_id") public int providerId;
        @JsonProperty("provider_name") public String providerName;
        @JsonProperty("display_priority") public int displayPriority;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbGenre {
        public int id;
        public String name;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbNetwork {
        public int id;
        public String name;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbCredits {
        public List<TmdbCast> cast = new ArrayList<>();
        public List<TmdbCrew> crew = new ArrayList<>();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbCast {
        public String name;
        public String character;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbCrew {
        public String name;
        public String job;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class TmdbExternalIds {
        @JsonProperty("imdb_id") public String imdbId;
    }
}
