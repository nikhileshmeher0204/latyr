package com.latyr.api.integration.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Immutable DTO representing GitHub search response and items.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record GitHubSearchResultDTO(
        @JsonProperty("total_count") int totalCount,
        @JsonProperty("incomplete_results") boolean incompleteResults,
        @JsonProperty("items") List<ItemDTO> items
) {
    public GitHubSearchResultDTO {
        items = items == null ? List.of() : List.copyOf(items);
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ItemDTO(
            @JsonProperty("id") long id,
            @JsonProperty("name") String name,
            @JsonProperty("full_name") String fullName,
            @JsonProperty("html_url") String htmlUrl,
            @JsonProperty("description") String description,
            @JsonProperty("stargazers_count") int stars,
            @JsonProperty("forks_count") int forks,
            @JsonProperty("language") String language,
            @JsonProperty("fork") boolean isFork,
            @JsonProperty("owner") GitHubRepoDetailsDTO.OwnerDTO owner
    ) {}
}
