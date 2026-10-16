package com.latyr.api;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.enrichment.GitHubEntityEnricher;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.integration.GitHubClient;
import com.latyr.api.integration.dto.GitHubRepoDetailsDTO;
import com.latyr.api.integration.dto.GitHubSearchResultDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class GitHubEntityEnricherTest {

    private GitHubClient gitHubClient;
    private GitHubEntityEnricher enricher;

    @BeforeEach
    void setUp() {
        gitHubClient = mock(GitHubClient.class);
        enricher = new GitHubEntityEnricher(gitHubClient);
    }

    @Test
    @DisplayName("Direct Lookup Strategy succeeds when predicted_owner_and_repo exists and meets quality gate")
    void testDirectLookupSuccess() {
        GitHubRepoDetailsDTO repoMock = new GitHubRepoDetailsDTO(
                "supabase",
                "supabase/supabase",
                "The open source Firebase alternative",
                "https://github.com/supabase/supabase",
                "https://supabase.com",
                74000,
                5800,
                820,
                350,
                "TypeScript",
                new GitHubRepoDetailsDTO.OwnerDTO("supabase", "https://avatars.githubusercontent.com/u/54469796", "Organization"),
                new GitHubRepoDetailsDTO.LicenseDTO("apache-2.0", "Apache License 2.0", "Apache-2.0", "https://api.github.com/licenses/apache-2.0"),
                List.of("database", "postgres", "realtime"),
                "master",
                "2026-10-16T12:00:00Z",
                false,
                false
        );

        when(gitHubClient.getRepository("supabase", "supabase")).thenReturn(Optional.of(repoMock));

        AIProvider.AIEntity rawEntity = new AIProvider.AIEntity(
                EntityType.GITHUB_REPO,
                "Supabase",
                "Open source database tool",
                null,
                ActionCTA.OPEN_GITHUB,
                Map.of("predicted_owner_and_repo", "supabase/supabase")
        );

        AIProvider.AIEntity enriched = enricher.enrich(rawEntity);

        assertNotNull(enriched);
        assertEquals(EntityType.GITHUB_REPO, enriched.entityType());
        assertEquals("supabase/supabase", enriched.title());
        assertEquals("https://github.com/supabase/supabase", enriched.externalUrl());
        assertEquals(74000, enriched.metadata().get("stars"));
        assertEquals("TypeScript", enriched.metadata().get("language"));
        assertEquals("Apache-2.0", enriched.metadata().get("license"));

        // Audit Telemetry check
        assertTrue(enriched.metadata().containsKey("resolution_audit"));
        @SuppressWarnings("unchecked")
        Map<String, Object> audit = (Map<String, Object>) enriched.metadata().get("resolution_audit");
        assertEquals("DIRECT_LOOKUP_SUCCESS", audit.get("strategy_applied"));
        assertEquals("GITHUB_REST_V3", audit.get("source_provider"));
        assertEquals("supabase/supabase", audit.get("predicted_target"));
        assertEquals("supabase/supabase", audit.get("resolved_target"));
        assertNull(audit.get("search_query_used"));

        verify(gitHubClient, times(1)).getRepository("supabase", "supabase");
        verify(gitHubClient, never()).searchRepositories(anyString(), anyInt());
    }

    @Test
    @DisplayName("Search Fallback Strategy activates when direct lookup 404s and search finds qualified repo")
    void testSearchFallbackSuccess() {
        when(gitHubClient.getRepository("excalidraw", "excalidraw")).thenReturn(Optional.empty());

        GitHubSearchResultDTO.ItemDTO searchItem = new GitHubSearchResultDTO.ItemDTO(
                12345,
                "excalidraw",
                "excalidraw/excalidraw",
                "https://github.com/excalidraw/excalidraw",
                "Virtual whiteboard for sketching",
                134000,
                15000,
                "TypeScript",
                false,
                new GitHubRepoDetailsDTO.OwnerDTO("excalidraw", "https://avatars.githubusercontent.com/u/excalidraw", "Organization")
        );

        when(gitHubClient.searchRepositories(contains("in:name"), eq(3)))
                .thenReturn(List.of(searchItem));

        GitHubRepoDetailsDTO fullDetailsMock = new GitHubRepoDetailsDTO(
                "excalidraw",
                "excalidraw/excalidraw",
                "Virtual whiteboard for sketching hand-drawn like diagrams",
                "https://github.com/excalidraw/excalidraw",
                "https://excalidraw.com",
                134000,
                15000,
                3200,
                510,
                "TypeScript",
                new GitHubRepoDetailsDTO.OwnerDTO("excalidraw", "https://avatars.githubusercontent.com/u/excalidraw", "Organization"),
                new GitHubRepoDetailsDTO.LicenseDTO("mit", "MIT License", "MIT", "https://api.github.com/licenses/mit"),
                List.of("whiteboard", "diagrams"),
                "master",
                "2026-10-15T10:00:00Z",
                false,
                false
        );

        when(gitHubClient.getRepository("excalidraw", "excalidraw")).thenReturn(Optional.of(fullDetailsMock));

        AIProvider.AIEntity rawEntity = new AIProvider.AIEntity(
                EntityType.GITHUB_REPO,
                "Excalidraw",
                "Whiteboard tool",
                null,
                ActionCTA.OPEN_GITHUB,
                Map.of(
                        "predicted_owner_and_repo", "wrong/excalidraw",
                        "search_query_keywords", "excalidraw whiteboard"
                )
        );

        when(gitHubClient.getRepository("wrong", "excalidraw")).thenReturn(Optional.empty());

        AIProvider.AIEntity enriched = enricher.enrich(rawEntity);

        assertNotNull(enriched);
        assertEquals(EntityType.GITHUB_REPO, enriched.entityType());
        assertEquals("excalidraw/excalidraw", enriched.title());
        assertEquals(134000, enriched.metadata().get("stars"));

        @SuppressWarnings("unchecked")
        Map<String, Object> audit = (Map<String, Object>) enriched.metadata().get("resolution_audit");
        assertEquals("SEARCH_FALLBACK_SUCCESS", audit.get("strategy_applied"));
        assertEquals("DIRECT_LOOKUP_404", audit.get("fallback_reason"));
        assertEquals("excalidraw/excalidraw", audit.get("resolved_target"));
    }

    @Test
    @DisplayName("Cleanly downgrades to TOOL when neither direct lookup nor search yields a qualified repository")
    void testCleanDowngradeToTool() {
        when(gitHubClient.searchRepositories(anyString(), anyInt())).thenReturn(Collections.emptyList());

        AIProvider.AIEntity rawEntity = new AIProvider.AIEntity(
                EntityType.GITHUB_REPO,
                "Notion",
                "All-in-one workspace",
                null,
                ActionCTA.OPEN_GITHUB,
                Map.of()
        );

        AIProvider.AIEntity enriched = enricher.enrich(rawEntity);

        assertNotNull(enriched);
        assertEquals(EntityType.TOOL, enriched.entityType());
        assertEquals(ActionCTA.EXPLORE, enriched.actionCta());
        assertTrue(enriched.externalUrl().contains("google.com/search"));

        @SuppressWarnings("unchecked")
        Map<String, Object> audit = (Map<String, Object>) enriched.metadata().get("resolution_audit");
        assertEquals("DOWNGRADED_TO_TOOL", audit.get("strategy_applied"));
        assertNull(audit.get("resolved_target"));
    }

    @Test
    @DisplayName("Promotes TOOL entity to GITHUB_REPO when GitHub signals are present and repo resolves")
    void testPromotesToolWithGitHubSignalsToGitHubRepo() {
        GitHubSearchResultDTO.ItemDTO searchItem = new GitHubSearchResultDTO.ItemDTO(
                1104332987,
                "MiroFish",
                "666ghj/MiroFish",
                "https://github.com/666ghj/MiroFish",
                "Universal Swarm Intelligence Engine",
                79000,
                12000,
                "Python",
                false,
                new GitHubRepoDetailsDTO.OwnerDTO("666ghj", "https://avatars.githubusercontent.com/u/110395318", "User")
        );

        when(gitHubClient.searchRepositories(contains("in:name"), eq(3)))
                .thenReturn(List.of(searchItem));

        GitHubRepoDetailsDTO fullDetailsMock = new GitHubRepoDetailsDTO(
                "MiroFish",
                "666ghj/MiroFish",
                "A Simple and Universal Swarm Intelligence Engine",
                "https://github.com/666ghj/MiroFish",
                "https://mirofish.ai",
                79000,
                12000,
                148,
                79000,
                "Python",
                new GitHubRepoDetailsDTO.OwnerDTO("666ghj", "https://avatars.githubusercontent.com/u/110395318", "User"),
                new GitHubRepoDetailsDTO.LicenseDTO("agpl-3.0", "AGPL-3.0", "AGPL-3.0", ""),
                List.of("swarm"),
                "main",
                "2026-10-16T12:00:00Z",
                false,
                false
        );

        when(gitHubClient.getRepository("666ghj", "MiroFish")).thenReturn(Optional.of(fullDetailsMock));

        AIProvider.AIEntity rawToolEntity = new AIProvider.AIEntity(
                EntityType.TOOL,
                "MiroFish",
                "An open-source AI tool that simulates market reactions",
                null,
                ActionCTA.EXPLORE,
                Map.of(
                        "predicted_owner_and_repo", "MiroFish/MiroFish",
                        "search_query_keywords", "MiroFish AI market simulation"
                )
        );

        assertTrue(enricher.supports(rawToolEntity));

        AIProvider.AIEntity enriched = enricher.enrich(rawToolEntity);

        assertNotNull(enriched);
        assertEquals(EntityType.GITHUB_REPO, enriched.entityType());
        assertEquals("666ghj/MiroFish", enriched.title());
        assertEquals("https://github.com/666ghj/MiroFish", enriched.externalUrl());
        assertEquals(ActionCTA.OPEN_GITHUB, enriched.actionCta());
        assertEquals(79000, enriched.metadata().get("stars"));
        assertEquals("Python", enriched.metadata().get("language"));
    }
}
