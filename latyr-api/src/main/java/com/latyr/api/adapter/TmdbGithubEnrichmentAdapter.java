package com.latyr.api.adapter;

import com.latyr.api.domain.enums.EntityType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.*;

@Component
public class TmdbGithubEnrichmentAdapter implements EntityEnrichmentProvider {

    private static final Logger log = LoggerFactory.getLogger(TmdbGithubEnrichmentAdapter.class);

    @Value("${tmdb.api.key:}")
    private String tmdbApiKey;

    @Value("${github.api.token:}")
    private String githubApiToken;

    private final WebClient webClient;

    public TmdbGithubEnrichmentAdapter(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.build();
    }

    @Override
    public List<AIProvider.AIEntity> enrichEntities(List<AIProvider.AIEntity> entities) {
        if (entities == null || entities.isEmpty()) {
            return Collections.emptyList();
        }

        List<AIProvider.AIEntity> enriched = new ArrayList<>();
        for (AIProvider.AIEntity entity : entities) {
            try {
                if (entity.entityType() == EntityType.TV_SHOW || entity.entityType() == EntityType.MOVIE) {
                    enriched.add(enrichWithTmdb(entity));
                } else if (entity.entityType() == EntityType.GITHUB_REPO) {
                    enriched.add(enrichWithGithub(entity));
                } else {
                    enriched.add(entity);
                }
            } catch (Exception e) {
                log.warn("Secondary enrichment failed for entity '{}': {}. Proceeding without enrichment.", entity.title(), e.getMessage());
                enriched.add(entity);
            }
        }
        return enriched;
    }

    @SuppressWarnings("unchecked")
    private AIProvider.AIEntity enrichWithTmdb(AIProvider.AIEntity entity) {
        Map<String, Object> metadata = new HashMap<>(entity.metadata() != null ? entity.metadata() : Map.of());

        if (tmdbApiKey != null && !tmdbApiKey.trim().isEmpty()) {
            try {
                String searchUrl = "https://api.themoviedb.org/3/search/multi?api_key=" + tmdbApiKey.trim() + "&query=" + entity.title();
                Map<String, Object> response = webClient.get()
                        .uri(searchUrl)
                        .retrieve()
                        .bodyToMono(new org.springframework.core.ParameterizedTypeReference<Map<String, Object>>() {})
                        .block(Duration.ofSeconds(5));

                if (response != null) {
                    List<Map<String, Object>> results = (List<Map<String, Object>>) response.get("results");
                    if (results != null && !results.isEmpty()) {
                        Map<String, Object> top = results.get(0);
                        String posterPath = (String) top.get("poster_path");
                        if (posterPath != null) {
                            metadata.put("poster_url", "https://image.tmdb.org/t/p/w500" + posterPath);
                        }
                        if (top.containsKey("vote_average")) {
                            metadata.put("rating", top.get("vote_average"));
                        }
                        if (top.containsKey("first_air_date")) {
                            metadata.put("release_year", top.get("first_air_date").toString().split("-")[0]);
                        } else if (top.containsKey("release_date")) {
                            metadata.put("release_year", top.get("release_date").toString().split("-")[0]);
                        }
                    }
                }
            } catch (Exception e) {
                log.debug("TMDB lookup failed for {}: {}", entity.title(), e.getMessage());
            }
        } else {
            // Default fallback poster if none exists
            if (!metadata.containsKey("poster_url")) {
                metadata.put("poster_url", "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&q=80");
            }
        }

        return new AIProvider.AIEntity(
                entity.entityType(),
                entity.title(),
                entity.description(),
                entity.externalUrl(),
                entity.actionCta(),
                metadata
        );
    }

    @SuppressWarnings("unchecked")
    private AIProvider.AIEntity enrichWithGithub(AIProvider.AIEntity entity) {
        Map<String, Object> metadata = new HashMap<>(entity.metadata() != null ? entity.metadata() : Map.of());

        String repoPath = extractGithubRepo(entity.externalUrl() != null ? entity.externalUrl() : entity.title());
        if (repoPath != null) {
            try {
                var request = webClient.get().uri("https://api.github.com/repos/" + repoPath);
                if (githubApiToken != null && !githubApiToken.trim().isEmpty()) {
                    request.header("Authorization", "Bearer " + githubApiToken.trim());
                }

                Map<String, Object> repoData = request.retrieve()
                        .bodyToMono(new org.springframework.core.ParameterizedTypeReference<Map<String, Object>>() {})
                        .block(Duration.ofSeconds(5));

                if (repoData != null) {
                    if (repoData.containsKey("stargazers_count")) {
                        metadata.put("stars", repoData.get("stargazers_count"));
                    }
                    if (repoData.containsKey("language")) {
                        metadata.put("language", repoData.get("language"));
                    }
                    if (repoData.containsKey("html_url") && entity.externalUrl() == null) {
                        return new AIProvider.AIEntity(
                                entity.entityType(),
                                entity.title(),
                                entity.description(),
                                (String) repoData.get("html_url"),
                                entity.actionCta(),
                                metadata
                        );
                    }
                }
            } catch (Exception e) {
                log.debug("GitHub lookup failed for {}: {}", repoPath, e.getMessage());
            }
        }

        return new AIProvider.AIEntity(
                entity.entityType(),
                entity.title(),
                entity.description(),
                entity.externalUrl(),
                entity.actionCta(),
                metadata
        );
    }

    private String extractGithubRepo(String input) {
        if (input == null) return null;
        if (input.contains("github.com/")) {
            String[] parts = input.split("github\\.com/");
            if (parts.length > 1) {
                String sub = parts[1].replaceAll("/$", "");
                String[] segments = sub.split("/");
                if (segments.length >= 2) {
                    return segments[0] + "/" + segments[1];
                }
            }
        }
        String[] segments = input.trim().split("/");
        if (segments.length == 2 && !input.contains(" ")) {
            return input.trim();
        }
        return null;
    }
}
