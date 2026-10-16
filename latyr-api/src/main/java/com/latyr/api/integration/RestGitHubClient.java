package com.latyr.api.integration;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.latyr.api.integration.dto.GitHubRepoDetailsDTO;
import com.latyr.api.integration.dto.GitHubSearchResultDTO;
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
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Production-grade, virtual-thread friendly REST implementation of GitHubClient.
 * Incorporates concurrency throttling, header authorization, and query sanitization.
 */
@Component
public class RestGitHubClient implements GitHubClient {

    private static final Logger log = LoggerFactory.getLogger(RestGitHubClient.class);

    private final String apiToken;
    private final String baseUrl;
    private final Duration connectTimeout;
    private final Duration readTimeout;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    // Rate-limit and concurrency tracking
    private final Semaphore concurrencyThrottle = new Semaphore(5);
    private final AtomicInteger lastRemainingRateLimit = new AtomicInteger(5000);

    public RestGitHubClient(
            @Value("${latyr.enrichment.github.api-token:${GITHUB_TOKEN:}}") String apiToken,
            @Value("${latyr.enrichment.github.base-url:https://api.github.com}") String baseUrl,
            @Value("${latyr.enrichment.github.connect-timeout-ms:2500}") int connectTimeoutMs,
            @Value("${latyr.enrichment.github.read-timeout-ms:3000}") int readTimeoutMs) {
        this.apiToken = apiToken != null ? apiToken.trim() : "";
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        this.connectTimeout = Duration.ofMillis(connectTimeoutMs);
        this.readTimeout = Duration.ofMillis(readTimeoutMs);

        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(this.connectTimeout)
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();

        this.objectMapper = new ObjectMapper()
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        if (isConfigured()) {
            log.info("Initialized RestGitHubClient with authenticated token (5,000 req/hr tier)");
        } else {
            log.warn("RestGitHubClient initialized without token. Unauthenticated rate limit is 60 req/hr!");
        }
    }

    @Override
    public boolean isConfigured() {
        return !apiToken.isBlank();
    }

    public int getLastRemainingRateLimit() {
        return lastRemainingRateLimit.get();
    }

    @Override
    public Optional<GitHubRepoDetailsDTO> getRepository(String owner, String repo) {
        if (owner == null || owner.isBlank() || repo == null || repo.isBlank()) {
            return Optional.empty();
        }

        String sanitizedOwner = sanitizePathSegment(owner);
        String sanitizedRepo = sanitizePathSegment(repo);
        String endpoint = "%s/repos/%s/%s".formatted(baseUrl, sanitizedOwner, sanitizedRepo);

        try {
            concurrencyThrottle.acquire();
            try {
                HttpRequest.Builder reqBuilder = HttpRequest.newBuilder()
                        .uri(URI.create(endpoint))
                        .timeout(readTimeout)
                        .header("Accept", "application/vnd.github+json")
                        .header("User-Agent", "Latyr-App")
                        .header("X-GitHub-Api-Version", "2022-11-28")
                        .GET();

                if (isConfigured()) {
                    reqBuilder.header("Authorization", "Bearer " + apiToken);
                }

                HttpResponse<String> response = httpClient.send(reqBuilder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
                updateRateLimitHeaders(response);

                if (response.statusCode() == 200) {
                    GitHubRepoDetailsDTO dto = objectMapper.readValue(response.body(), GitHubRepoDetailsDTO.class);
                    return Optional.ofNullable(dto);
                } else if (response.statusCode() == 404) {
                    log.debug("GitHub repository not found: {}/{}", sanitizedOwner, sanitizedRepo);
                    return Optional.empty();
                } else {
                    log.warn("GitHub API error [HTTP {}] for {}/{}: {}", response.statusCode(), sanitizedOwner, sanitizedRepo, response.body());
                    return Optional.empty();
                }
            } finally {
                concurrencyThrottle.release();
            }
        } catch (Exception e) {
            log.error("Failed to fetch repository {}/{}: {}", sanitizedOwner, sanitizedRepo, e.getMessage());
            return Optional.empty();
        }
    }

    @Override
    public List<GitHubSearchResultDTO.ItemDTO> searchRepositories(String query, int limit) {
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }

        String sanitizedQuery = sanitizeSearchQuery(query);
        int clampedLimit = Math.max(1, Math.min(limit, 10));
        String encodedQuery = URLEncoder.encode(sanitizedQuery, StandardCharsets.UTF_8);
        String endpoint = "%s/search/repositories?q=%s&sort=stars&order=desc&per_page=%d".formatted(baseUrl, encodedQuery, clampedLimit);

        try {
            concurrencyThrottle.acquire();
            try {
                HttpRequest.Builder reqBuilder = HttpRequest.newBuilder()
                        .uri(URI.create(endpoint))
                        .timeout(readTimeout)
                        .header("Accept", "application/vnd.github+json")
                        .header("User-Agent", "Latyr-App")
                        .header("X-GitHub-Api-Version", "2022-11-28")
                        .GET();

                if (isConfigured()) {
                    reqBuilder.header("Authorization", "Bearer " + apiToken);
                }

                HttpResponse<String> response = httpClient.send(reqBuilder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
                updateRateLimitHeaders(response);

                if (response.statusCode() == 200) {
                    GitHubSearchResultDTO result = objectMapper.readValue(response.body(), GitHubSearchResultDTO.class);
                    return result.items() != null ? result.items() : Collections.emptyList();
                } else if (response.statusCode() == 403 || response.statusCode() == 429) {
                    log.warn("GitHub Search API rate limit reached [HTTP {}]: {}", response.statusCode(), response.body());
                    return Collections.emptyList();
                } else {
                    log.warn("GitHub search error [HTTP {}] for query '{}': {}", response.statusCode(), sanitizedQuery, response.body());
                    return Collections.emptyList();
                }
            } finally {
                concurrencyThrottle.release();
            }
        } catch (Exception e) {
            log.error("Failed to execute GitHub search for '{}': {}", sanitizedQuery, e.getMessage());
            return Collections.emptyList();
        }
    }

    private void updateRateLimitHeaders(HttpResponse<?> response) {
        response.headers().firstValue("x-ratelimit-remaining").ifPresent(val -> {
            try {
                lastRemainingRateLimit.set(Integer.parseInt(val));
            } catch (NumberFormatException ignored) {}
        });
    }

    private String sanitizePathSegment(String segment) {
        if (segment == null) return "";
        return segment.trim().replaceAll("[^a-zA-Z0-9_.-]", "");
    }

    private String sanitizeSearchQuery(String query) {
        if (query == null) return "";
        // Retain alphanumeric, spaces, hyphens, and specific search qualifiers like in:name
        return query.trim()
                .replaceAll("[^a-zA-Z0-9\\-\\s._:]", "")
                .replaceAll("\\s+", " ");
    }
}
