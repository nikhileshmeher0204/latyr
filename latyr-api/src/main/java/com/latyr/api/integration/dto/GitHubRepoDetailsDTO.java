package com.latyr.api.integration.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Immutable DTO representing GitHub repository details and metadata.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record GitHubRepoDetailsDTO(
        @JsonProperty("name") String name,
        @JsonProperty("full_name") String fullName,
        @JsonProperty("description") String description,
        @JsonProperty("html_url") String htmlUrl,
        @JsonProperty("homepage") String homepage,
        @JsonProperty("stargazers_count") int stars,
        @JsonProperty("forks_count") int forks,
        @JsonProperty("open_issues_count") int openIssues,
        @JsonProperty("subscribers_count") int watchers,
        @JsonProperty("language") String language,
        @JsonProperty("owner") OwnerDTO owner,
        @JsonProperty("license") LicenseDTO license,
        @JsonProperty("topics") List<String> topics,
        @JsonProperty("default_branch") String defaultBranch,
        @JsonProperty("pushed_at") String pushedAt,
        @JsonProperty("archived") boolean isArchived,
        @JsonProperty("fork") boolean isFork
) {
    public GitHubRepoDetailsDTO {
        topics = topics == null ? List.of() : List.copyOf(topics);
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record OwnerDTO(
            @JsonProperty("login") String login,
            @JsonProperty("avatar_url") String avatarUrl,
            @JsonProperty("type") String type
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record LicenseDTO(
            @JsonProperty("key") String key,
            @JsonProperty("name") String name,
            @JsonProperty("spdx_id") String spdxId,
            @JsonProperty("url") String url
    ) {}
}
