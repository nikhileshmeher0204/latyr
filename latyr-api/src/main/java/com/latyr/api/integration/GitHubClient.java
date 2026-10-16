package com.latyr.api.integration;

import com.latyr.api.integration.dto.GitHubRepoDetailsDTO;
import com.latyr.api.integration.dto.GitHubSearchResultDTO;

import java.util.List;
import java.util.Optional;

/**
 * Facade contract for GitHub integration.
 * Abstracted behind this interface to ensure zero coupling in business and enrichment services.
 */
public interface GitHubClient {

    /**
     * Checks if the client has authentication credentials configured.
     */
    boolean isConfigured();

    /**
     * Direct repository lookup by owner and repository name.
     * Uses the 5,000 req/hr rate limit pool.
     */
    Optional<GitHubRepoDetailsDTO> getRepository(String owner, String repo);

    /**
     * Search repositories with star-ranked ordering.
     * Uses the 30 req/min search rate limit pool.
     */
    List<GitHubSearchResultDTO.ItemDTO> searchRepositories(String query, int limit);
}
