package com.latyr.api.integration;

import com.latyr.api.client.OmdbCatalog;
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
 * Production-grade, virtual-thread friendly client for OMDb (Open Movie Database / IMDb).
 * Provides authentic IMDb scores, vote counts, Rotten Tomatoes ratings, content maturity (Rated),
 * awards, directors, writers, and full cast metadata.
 */
@Component
public class OmdbClient implements OmdbCatalog {

    private static final Logger log = LoggerFactory.getLogger(OmdbClient.class);

    private final String apiKey;
    private final String baseUrl;
    private final Duration connectTimeout;
    private final Duration readTimeout;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public OmdbClient(
            @Value("${latyr.enrichment.omdb.api-key:}") String apiKey,
            @Value("${latyr.enrichment.omdb.base-url:https://www.omdbapi.com}") String baseUrl,
            @Value("${latyr.enrichment.omdb.connect-timeout-ms:1500}") int connectTimeoutMs,
            @Value("${latyr.enrichment.omdb.read-timeout-ms:1500}") int readTimeoutMs) {
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
     * Fetch authentic IMDb metadata using an exact IMDb ID (e.g. "tt13229894").
     * 100% deterministic with zero title-clash ambiguity.
     */
    public Optional<OmdbCatalog.OmdbMovieResponse> getByImdbId(String imdbId) {
        if (!isConfigured()) throw new ProviderOperationException("OMDB_NOT_CONFIGURED", PERMANENT);
        if (imdbId == null || imdbId.isBlank()) {
            return Optional.empty();
        }

        String trimmedId = imdbId.trim();
        String url = baseUrl + "/?i=" + encode(trimmedId) + "&plot=full&apikey=" + apiKey;

        try {
            String json = executeGet(url);
            if (json == null) return Optional.empty();

            OmdbMovieResponse response = objectMapper.readValue(json, OmdbMovieResponse.class);
            if (response != null && response.isSuccess()) {
                return Optional.of(toCatalog(response));
            } else {
                return missingOrFailure(response);
            }
        } catch (ProviderOperationException failure) {
            throw failure;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new ProviderOperationException("OMDB_INTERRUPTED", RETRYABLE);
        } catch (Exception failure) {
            throw new ProviderOperationException("OMDB_UNAVAILABLE", RETRYABLE);
        }
    }

    /**
     * Fetch metadata by exact title and optional year as a secondary fallback.
     */
    public Optional<OmdbCatalog.OmdbMovieResponse> getByTitle(String title, Integer year) {
        if (!isConfigured()) throw new ProviderOperationException("OMDB_NOT_CONFIGURED", PERMANENT);
        if (title == null || title.isBlank()) {
            return Optional.empty();
        }

        StringBuilder url = new StringBuilder(baseUrl)
                .append("/?t=")
                .append(encode(title.trim()))
                .append("&plot=full&apikey=")
                .append(apiKey);

        if (year != null && year > 1900 && year < 2100) {
            url.append("&y=").append(year);
        }

        try {
            String json = executeGet(url.toString());
            if (json == null) return Optional.empty();

            OmdbMovieResponse response = objectMapper.readValue(json, OmdbMovieResponse.class);
            if (response != null && response.isSuccess()) {
                return Optional.of(toCatalog(response));
            }
            return missingOrFailure(response);
        } catch (ProviderOperationException failure) {
            throw failure;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new ProviderOperationException("OMDB_INTERRUPTED", RETRYABLE);
        } catch (Exception failure) {
            throw new ProviderOperationException("OMDB_UNAVAILABLE", RETRYABLE);
        }
    }

    private Optional<OmdbCatalog.OmdbMovieResponse> missingOrFailure(OmdbMovieResponse response) {
        String error = response != null && response.error != null ? response.error.toLowerCase(Locale.ROOT) : "";
        if (error.contains("not found")) return Optional.empty();
        throw new ProviderOperationException(error.contains("api key") ? "OMDB_AUTH_FAILED" : "OMDB_UNAVAILABLE",
                error.contains("api key") ? PERMANENT : RETRYABLE);
    }

    private String executeGet(String url) throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(readTimeout)
                .header("Accept", "application/json")
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        int status = response.statusCode();

        if (status == 200) {
            return response.body();
        } else if (status == 404) {
            return null;
        }
        throw new ProviderOperationException("OMDB_HTTP_" + status,
                status == 429 || status >= 500 ? RETRYABLE : PERMANENT);
    }

    private String encode(String text) {
        return URLEncoder.encode(text, StandardCharsets.UTF_8);
    }

    private static OmdbCatalog.OmdbMovieResponse toCatalog(OmdbMovieResponse raw) {
        if (raw == null) return null;
        return new OmdbCatalog.OmdbMovieResponse(
            raw.title,
            raw.year,
            raw.rated,
            raw.released,
            raw.runtime,
            raw.genre,
            raw.director,
            raw.writer,
            raw.actors,
            raw.plot,
            raw.language,
            raw.country,
            raw.awards,
            raw.poster,
            raw.ratings == null ? List.of() : raw.ratings.stream().filter(Objects::nonNull).map(OmdbClient::toCatalog).toList(),
            raw.metascore,
            raw.imdbRating,
            raw.imdbVotes,
            raw.imdbId,
            raw.type,
            raw.boxOffice);
    }

    private static OmdbCatalog.OmdbRating toCatalog(OmdbRating raw) {
        if (raw == null) return null;
        return new OmdbCatalog.OmdbRating(
            raw.source,
            raw.value);
    }

    // --- OMDb DTOs ---

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class OmdbMovieResponse {
        @JsonProperty("Title") public String title;
        @JsonProperty("Year") public String year;
        @JsonProperty("Rated") public String rated;
        @JsonProperty("Released") public String released;
        @JsonProperty("Runtime") public String runtime;
        @JsonProperty("Genre") public String genre;
        @JsonProperty("Director") public String director;
        @JsonProperty("Writer") public String writer;
        @JsonProperty("Actors") public String actors;
        @JsonProperty("Plot") public String plot;
        @JsonProperty("Language") public String language;
        @JsonProperty("Country") public String country;
        @JsonProperty("Awards") public String awards;
        @JsonProperty("Poster") public String poster;
        @JsonProperty("Ratings") public List<OmdbRating> ratings = new ArrayList<>();
        @JsonProperty("Metascore") public String metascore;
        public String imdbRating;
        public String imdbVotes;
        @JsonProperty("imdbID") public String imdbId;
        @JsonProperty("Type") public String type;
        @JsonProperty("BoxOffice") public String boxOffice;
        @JsonProperty("Response") public String response;
        @JsonProperty("Error") public String error;

        public boolean isSuccess() {
            return "True".equalsIgnoreCase(response);
        }

        public boolean hasValue(String val) {
            return val != null && !val.isBlank() && !"N/A".equalsIgnoreCase(val.trim());
        }

        public Double getParsedImdbRating() {
            if (hasValue(imdbRating)) {
                try {
                    return Double.parseDouble(imdbRating.trim());
                } catch (NumberFormatException ignored) {}
            }
            return null;
        }

        public String getRottenTomatoesRating() {
            if (ratings != null) {
                for (OmdbRating r : ratings) {
                    if ("Rotten Tomatoes".equalsIgnoreCase(r.source)) {
                        return r.value;
                    }
                }
            }
            return null;
        }

        public String getMetacriticRating() {
            if (ratings != null) {
                for (OmdbRating r : ratings) {
                    if ("Metacritic".equalsIgnoreCase(r.source)) {
                        return r.value;
                    }
                }
            }
            if (hasValue(metascore)) {
                return metascore + "/100";
            }
            return null;
        }

        public List<String> getActorList() {
            if (!hasValue(actors)) return Collections.emptyList();
            return Arrays.stream(actors.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }

        public List<String> getGenreList() {
            if (!hasValue(genre)) return Collections.emptyList();
            return Arrays.stream(genre.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }

        public List<String> getWriterList() {
            if (!hasValue(writer)) return Collections.emptyList();
            return Arrays.stream(writer.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class OmdbRating {
        @JsonProperty("Source") public String source;
        @JsonProperty("Value") public String value;
    }
}
