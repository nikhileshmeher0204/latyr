package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.integration.GitHubClient;
import com.latyr.api.integration.dto.GitHubRepoDetailsDTO;
import com.latyr.api.integration.dto.GitHubSearchResultDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.*;

/**
 * Production-grade GitHub Entity Enricher.
 * Orchestrates Direct Lookup (5,000 req/hr) and Star-Ranked Search Fallback (30 req/min).
 * Records complete resolution audit telemetry in compliance with Latyr Architecture Guideline #7.
 */
@Component
@Order(30)
public class GitHubEntityEnricher implements EntityEnricher {

    private static final Logger log = LoggerFactory.getLogger(GitHubEntityEnricher.class);
    private static final int MIN_DIRECT_STARS = 30;
    private static final int MIN_SEARCH_STARS = 100;

    private final GitHubClient gitHubClient;

    public GitHubEntityEnricher(GitHubClient gitHubClient) {
        this.gitHubClient = gitHubClient;
    }

    @Override
    public boolean supports(EntityType entityType) {
        return entityType == EntityType.GITHUB_REPO;
    }

    @Override
    public boolean supports(AIProvider.AIEntity entity) {
        if (entity == null) return false;
        if (entity.entityType() == EntityType.GITHUB_REPO) {
            return true;
        }
        // Safety Net: If AI classified as generic TOOL, check for strong GitHub/open-source signals
        if (entity.entityType() == EntityType.TOOL) {
            Map<String, Object> meta = entity.metadata();
            if (meta != null) {
                if (meta.containsKey("predicted_owner_and_repo") && meta.get("predicted_owner_and_repo") != null) {
                    return true;
                }
                if (meta.containsKey("search_query_keywords") && meta.get("search_query_keywords") != null) {
                    String kw = meta.get("search_query_keywords").toString().toLowerCase(Locale.ROOT);
                    if (kw.contains("github") || kw.contains("repo") || kw.contains("open source") || kw.contains("open-source")) {
                        return true;
                    }
                }
            }
            String desc = entity.description() != null ? entity.description().toLowerCase(Locale.ROOT) : "";
            if (desc.contains("github") || desc.contains("open-source") || desc.contains("open source") || desc.contains("starred")) {
                return true;
            }
            String url = entity.externalUrl() != null ? entity.externalUrl().toLowerCase(Locale.ROOT) : "";
            if (url.contains("github.com")) {
                return true;
            }
        }
        return false;
    }

    @Override
    public AIProvider.AIEntity enrich(AIProvider.AIEntity entity) {
        long startTime = System.currentTimeMillis();
        Map<String, Object> metadata = new HashMap<>(entity.metadata() != null ? entity.metadata() : Map.of());

        // 0. Cache check: If already enriched with stars and audit record, bypass external calls
        if (metadata.containsKey("stars") && metadata.containsKey("resolution_audit")) {
            metadata.put("resolution_strategy", "CACHED");
            metadata.put("resolution_source", "GITHUB_REST_V3");
            metadata.put("predicted_target", extractPredictedPath(entity, metadata));
            metadata.put("resolved_target", metadata.get("full_name"));
            metadata.put("resolution_latency_ms", 0L);
            metadata.put("resolved_at", Instant.now().toString());
            return new AIProvider.AIEntity(entity.entityType(), entity.title(), entity.description(), entity.externalUrl(), entity.actionCta(), metadata);
        }

        String predictedTarget = extractPredictedPath(entity, metadata);
        String resolvedTarget = null;
        String strategyApplied = null;
        String fallbackReason = null;
        String searchQueryUsed = null;
        GitHubRepoDetailsDTO resolvedDetails = null;

        // 1. Direct Lookup Strategy (Fast Path: 5,000 req/hr bucket)
        if (predictedTarget != null && predictedTarget.contains("/")) {
            String[] parts = predictedTarget.split("/", 2);
            String owner = parts[0].trim();
            String repo = parts[1].trim();

            if (!owner.isEmpty() && !repo.isEmpty()) {
                Optional<GitHubRepoDetailsDTO> directOpt = gitHubClient.getRepository(owner, repo);
                if (directOpt.isPresent()) {
                    GitHubRepoDetailsDTO candidate = directOpt.get();
                    if (candidate.stars() >= MIN_DIRECT_STARS || !candidate.isFork()) {
                        resolvedDetails = candidate;
                        resolvedTarget = candidate.fullName();
                        strategyApplied = "DIRECT_LOOKUP_SUCCESS";
                        log.info("Direct lookup succeeded for '{}/{}' (★ {})", owner, repo, candidate.stars());
                    } else {
                        fallbackReason = "DIRECT_LOOKUP_LOW_STARS_OR_FORK";
                        log.debug("Direct match '{}/{}' had insufficient stars (★ {}). Falling back to search.", owner, repo, candidate.stars());
                    }
                } else {
                    fallbackReason = "DIRECT_LOOKUP_404";
                }
            }
        }

        // 2. Star-Ranked Search Fallback Strategy (30 req/min bucket)
        if (resolvedDetails == null) {
            String cleanTitle = cleanSearchTerm(entity.title());
            String keywordQuery = extractKeywordSearchTerm(metadata);

            // 2a. Precision Search: clean title with in:name (e.g. "MiroFish in:name")
            if (!cleanTitle.isBlank()) {
                searchQueryUsed = cleanTitle + " in:name";
                List<GitHubSearchResultDTO.ItemDTO> searchResults = gitHubClient.searchRepositories(searchQueryUsed, 3);
                resolvedDetails = evaluateTopMatch(searchResults);
                if (resolvedDetails != null) {
                    resolvedTarget = resolvedDetails.fullName();
                    strategyApplied = "SEARCH_FALLBACK_SUCCESS";
                    log.info("Search fallback (in:name) succeeded for '{}' -> '{}' (★ {})", cleanTitle, resolvedTarget, resolvedDetails.stars());
                }
            }

            // 2b. Broader Search: clean title across name, description, and topics (e.g. "MiroFish")
            if (resolvedDetails == null && !cleanTitle.isBlank()) {
                searchQueryUsed = cleanTitle;
                List<GitHubSearchResultDTO.ItemDTO> searchResults = gitHubClient.searchRepositories(searchQueryUsed, 3);
                resolvedDetails = evaluateTopMatch(searchResults);
                if (resolvedDetails != null) {
                    resolvedTarget = resolvedDetails.fullName();
                    strategyApplied = "SEARCH_FALLBACK_SUCCESS";
                    log.info("Search fallback (broad title) succeeded for '{}' -> '{}' (★ {})", cleanTitle, resolvedTarget, resolvedDetails.stars());
                }
            }

            // 2c. Keyword Search: search_query_keywords if title search didn't resolve
            if (resolvedDetails == null && keywordQuery != null && !keywordQuery.isBlank() && !keywordQuery.equalsIgnoreCase(cleanTitle)) {
                searchQueryUsed = keywordQuery;
                List<GitHubSearchResultDTO.ItemDTO> searchResults = gitHubClient.searchRepositories(searchQueryUsed, 3);
                resolvedDetails = evaluateTopMatch(searchResults);
                if (resolvedDetails != null) {
                    resolvedTarget = resolvedDetails.fullName();
                    strategyApplied = "SEARCH_FALLBACK_SUCCESS";
                    log.info("Search fallback (keywords) succeeded for '{}' -> '{}' (★ {})", keywordQuery, resolvedTarget, resolvedDetails.stars());
                }
            }
        }

        long latencyMs = System.currentTimeMillis() - startTime;

        // 3. Evaluation & Quality Gate
        if (resolvedDetails != null) {
            // Apply enriched GitHub metadata
            metadata.put("full_name", resolvedDetails.fullName());
            metadata.put("repo_name", resolvedDetails.name());
            metadata.put("owner", resolvedDetails.owner() != null ? resolvedDetails.owner().login() : "");
            metadata.put("owner_avatar_url", resolvedDetails.owner() != null ? resolvedDetails.owner().avatarUrl() : "");
            metadata.put("stars", resolvedDetails.stars());
            metadata.put("forks", resolvedDetails.forks());
            metadata.put("open_issues", resolvedDetails.openIssues());
            metadata.put("watchers", resolvedDetails.watchers());
            metadata.put("language", resolvedDetails.language() != null ? resolvedDetails.language() : "Code");
            metadata.put("license", resolvedDetails.license() != null && resolvedDetails.license().spdxId() != null ? resolvedDetails.license().spdxId() : "Open Source");
            metadata.put("homepage", resolvedDetails.homepage() != null ? resolvedDetails.homepage() : "");
            metadata.put("topics", resolvedDetails.topics() != null ? resolvedDetails.topics() : Collections.emptyList());
            metadata.put("default_branch", resolvedDetails.defaultBranch() != null ? resolvedDetails.defaultBranch() : "main");
            metadata.put("pushed_at", resolvedDetails.pushedAt());
            metadata.put("is_archived", resolvedDetails.isArchived());

            // Build Audit Telemetry Record
            Map<String, Object> audit = new LinkedHashMap<>();
            audit.put("strategy_applied", strategyApplied);
            audit.put("source_provider", "GITHUB_REST_V3");
            audit.put("predicted_target", predictedTarget);
            audit.put("resolved_target", resolvedTarget);
            audit.put("search_query_used", searchQueryUsed);
            audit.put("fallback_reason", fallbackReason);
            audit.put("latency_ms", latencyMs);
            audit.put("resolved_at", Instant.now().toString());
            metadata.put("resolution_audit", audit);
            metadata.put("resolution_strategy", audit.get("strategy_applied"));
            metadata.put("resolution_source", audit.get("source_provider"));
            metadata.put("predicted_target", audit.get("predicted_target"));
            metadata.put("resolved_target", audit.get("resolved_target"));
            metadata.put("fallback_reason", audit.get("fallback_reason"));
            metadata.put("resolution_latency_ms", audit.get("latency_ms"));
            metadata.put("resolved_at", audit.get("resolved_at"));

            String canonicalUrl = resolvedDetails.htmlUrl() != null ? resolvedDetails.htmlUrl() : "https://github.com/" + resolvedTarget;
            String canonicalDescription = (resolvedDetails.description() != null && !resolvedDetails.description().isBlank())
                    ? resolvedDetails.description()
                    : entity.description();

            return new AIProvider.AIEntity(
                    EntityType.GITHUB_REPO,
                    resolvedDetails.fullName(),
                    canonicalDescription,
                    canonicalUrl,
                    ActionCTA.OPEN_GITHUB,
                    metadata
            );
        } else {
            // 4. Downscale Gate: Cleanly downgrade to general TOOL if no authentic repo was discovered
            log.info("No authentic GitHub repository verified for '{}'. Cleanly downgrading to TOOL.", entity.title());

            Map<String, Object> audit = new LinkedHashMap<>();
            audit.put("strategy_applied", "DOWNGRADED_TO_TOOL");
            audit.put("source_provider", "GITHUB_REST_V3");
            audit.put("predicted_target", predictedTarget);
            audit.put("resolved_target", null);
            audit.put("search_query_used", searchQueryUsed);
            audit.put("fallback_reason", fallbackReason != null ? fallbackReason : "NO_QUALIFIED_SEARCH_MATCHES");
            audit.put("latency_ms", latencyMs);
            audit.put("resolved_at", Instant.now().toString());
            metadata.put("resolution_audit", audit);
            metadata.put("resolution_strategy", audit.get("strategy_applied"));
            metadata.put("resolution_source", audit.get("source_provider"));
            metadata.put("predicted_target", audit.get("predicted_target"));
            metadata.put("resolved_target", audit.get("resolved_target"));
            metadata.put("fallback_reason", audit.get("fallback_reason"));
            metadata.put("resolution_latency_ms", audit.get("latency_ms"));
            metadata.put("resolved_at", audit.get("resolved_at"));

            String fallbackUrl = entity.externalUrl();
            if (fallbackUrl == null || fallbackUrl.isBlank()) {
                fallbackUrl = "https://www.google.com/search?q=" + entity.title().trim().replace(" ", "+");
            }

            return new AIProvider.AIEntity(
                    EntityType.TOOL,
                    entity.title(),
                    entity.description(),
                    fallbackUrl,
                    ActionCTA.EXPLORE,
                    metadata
            );
        }
    }

    private String extractPredictedPath(AIProvider.AIEntity entity, Map<String, Object> metadata) {
        if (metadata.containsKey("predicted_owner_and_repo") && metadata.get("predicted_owner_and_repo") != null) {
            String candidate = metadata.get("predicted_owner_and_repo").toString().trim();
            if (candidate.contains("/") && !candidate.contains(" ")) {
                return candidate;
            }
        }

        String url = entity.externalUrl();
        if (url != null && url.contains("github.com/")) {
            String path = url.substring(url.indexOf("github.com/") + 11).trim();
            if (path.endsWith("/")) path = path.substring(0, path.length() - 1);
            String[] segments = path.split("/");
            if (segments.length >= 2) {
                return segments[0] + "/" + segments[1];
            }
        }

        String title = entity.title() != null ? entity.title().trim() : "";
        if (title.contains("/") && !title.contains(" ")) {
            return title;
        }

        return null;
    }

    private GitHubRepoDetailsDTO evaluateTopMatch(List<GitHubSearchResultDTO.ItemDTO> searchResults) {
        if (searchResults == null || searchResults.isEmpty()) {
            return null;
        }
        GitHubSearchResultDTO.ItemDTO topMatch = searchResults.get(0);
        if (topMatch.stars() >= MIN_SEARCH_STARS && topMatch.owner() != null) {
            Optional<GitHubRepoDetailsDTO> fullDetailsOpt = gitHubClient.getRepository(topMatch.owner().login(), topMatch.name());
            return fullDetailsOpt.orElse(null);
        } else {
            log.debug("Top search result '{}' had insufficient stars (★ {} < {})", topMatch.fullName(), topMatch.stars(), MIN_SEARCH_STARS);
            return null;
        }
    }

    private String cleanSearchTerm(String title) {
        if (title == null) return "";
        return title.replaceAll("[^a-zA-Z0-9_-]", " ").trim();
    }

    private String extractKeywordSearchTerm(Map<String, Object> metadata) {
        if (metadata != null && metadata.containsKey("search_query_keywords") && metadata.get("search_query_keywords") != null) {
            String keywords = metadata.get("search_query_keywords").toString().trim();
            if (!keywords.isEmpty()) {
                return keywords;
            }
        }
        return null;
    }
}
