package com.latyr.api.integration;

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
 * Bounded by strict timeouts with zero-throw graceful degradation.
 */
@Component
public class TmdbClient {

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
    public List<TmdbItem> searchMovies(String query, Integer year) {
        if (!isConfigured() || query == null || query.isBlank()) {
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
    public List<TmdbItem> searchTv(String query, Integer year) {
        if (!isConfigured() || query == null || query.isBlank()) {
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
    public List<TmdbItem> searchMulti(String query) {
        if (!isConfigured() || query == null || query.isBlank()) {
            return Collections.emptyList();
        }

        String url = baseUrl + "/search/multi?query=" + encode(query) + "&include_adult=false";
        return executeSearch(url, null);
    }

    /**
     * Get detailed movie information including runtime, IMDb ID, and credits.
     */
    public Optional<TmdbMovieDetails> getMovieDetails(int movieId) {
        if (!isConfigured()) return Optional.empty();

        String url = baseUrl + "/movie/" + movieId + "?append_to_response=credits,external_ids";
        try {
            String json = executeGet(url);
            if (json == null) return Optional.empty();
            return Optional.ofNullable(objectMapper.readValue(json, TmdbMovieDetails.class));
        } catch (Exception e) {
            log.warn("Failed to fetch TMDB movie details for {}: {}", movieId, e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * Get detailed TV series information including seasons, episodes, networks, and credits.
     */
    public Optional<TmdbTvDetails> getTvDetails(int tvId) {
        if (!isConfigured()) return Optional.empty();

        String url = baseUrl + "/tv/" + tvId + "?append_to_response=credits,external_ids";
        try {
            String json = executeGet(url);
            if (json == null) return Optional.empty();
            return Optional.ofNullable(objectMapper.readValue(json, TmdbTvDetails.class));
        } catch (Exception e) {
            log.warn("Failed to fetch TMDB TV details for {}: {}", tvId, e.getMessage());
            return Optional.empty();
        }
    }

    private List<TmdbItem> executeSearch(String rawUrl, String defaultMediaType) {
        try {
            String json = executeGet(rawUrl);
            if (json == null) return Collections.emptyList();

            TmdbSearchResponse response = objectMapper.readValue(json, TmdbSearchResponse.class);
            if (response == null || response.results == null) return Collections.emptyList();

            for (TmdbItem item : response.results) {
                if (item.mediaType == null && defaultMediaType != null) {
                    item.mediaType = defaultMediaType;
                }
            }
            return response.results;
        } catch (Exception e) {
            log.warn("TMDB search query failed for '{}': {}", rawUrl, e.getMessage());
            return Collections.emptyList();
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
        } else if (status == 429) {
            log.warn("TMDB rate limit (429) encountered. Caller should queue for retry.");
            throw new IllegalStateException("TMDB_RATE_LIMITED_429");
        } else if (status == 404) {
            return null;
        } else {
            log.warn("TMDB request returned status {}: {}", status, response.body());
            return null;
        }
    }

    private String encode(String text) {
        return URLEncoder.encode(text, StandardCharsets.UTF_8);
    }

    // --- TMDB Payloads ---

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbSearchResponse {
        public List<TmdbItem> results = new ArrayList<>();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbItem {
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
    public static class TmdbMovieDetails {
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
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbTvDetails {
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
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbGenre {
        public int id;
        public String name;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbNetwork {
        public int id;
        public String name;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbCredits {
        public List<TmdbCast> cast = new ArrayList<>();
        public List<TmdbCrew> crew = new ArrayList<>();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbCast {
        public String name;
        public String character;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbCrew {
        public String name;
        public String job;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TmdbExternalIds {
        @JsonProperty("imdb_id") public String imdbId;
    }
}
