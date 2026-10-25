package com.latyr.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.latyr.api.controller.UserCollectionController;
import com.latyr.api.dto.CreateCollectionRequest;
import com.latyr.api.dto.UpdateCollectionRequest;
import com.latyr.api.dto.UserCollectionResponse;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.service.UserCollectionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class UserCollectionControllerTest {

    private MockMvc mockMvc;

    @Mock
    private UserCollectionService collectionService;

    private final ObjectMapper mapper = new ObjectMapper().registerModule(new JavaTimeModule());
    private UUID testUserId;
    private UUID testCollectionId;
    private UUID testEntityId;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
        testCollectionId = UUID.randomUUID();
        testEntityId = UUID.randomUUID();

        HandlerMethodArgumentResolver userResolver = new HandlerMethodArgumentResolver() {
            @Override
            public boolean supportsParameter(MethodParameter parameter) {
                return parameter.getParameterType().equals(AuthenticatedUser.class);
            }

            @Override
            public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
                                          NativeWebRequest webRequest, WebDataBinderFactory binderFactory) {
                return new AuthenticatedUser(testUserId, "firebase-uid", "test@latyr.com");
            }
        };

        UserCollectionController controller = new UserCollectionController(collectionService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setCustomArgumentResolvers(userResolver)
                .setMessageConverters(new MappingJackson2HttpMessageConverter(mapper))
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/collections returns user collections")
    void testGetUserCollections() throws Exception {
        UserCollectionResponse response = new UserCollectionResponse(
                testCollectionId,
                testUserId,
                "Weekend Thrillers",
                "Top thriller movies",
                "film_fill",
                "#28543A",
                3,
                List.of("https://example.com/poster.jpg"),
                false,
                Instant.now(),
                Instant.now()
        );

        when(collectionService.getUserCollections(testUserId)).thenReturn(List.of(response));

        mockMvc.perform(get("/api/v1/collections"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("Weekend Thrillers"))
                .andExpect(jsonPath("$[0].itemCount").value(3))
                .andExpect(jsonPath("$[0].previewArtworkUrls[0]").value("https://example.com/poster.jpg"));
    }

    @Test
    @DisplayName("POST /api/v1/collections creates collection")
    void testCreateCollection() throws Exception {
        CreateCollectionRequest request = new CreateCollectionRequest("Watchlist", "My movies", "film", "#123456");
        UserCollectionResponse response = new UserCollectionResponse(
                testCollectionId,
                testUserId,
                "Watchlist",
                "My movies",
                "film",
                "#123456",
                0,
                List.of(),
                false,
                Instant.now(),
                Instant.now()
        );

        when(collectionService.createCollection(eq(testUserId), any(CreateCollectionRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/v1/collections")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Watchlist"));
    }

    @Test
    @DisplayName("POST /api/v1/collections/{id}/entities/{entityId} adds entity")
    void testAddEntityToCollection() throws Exception {
        mockMvc.perform(post("/api/v1/collections/{id}/entities/{entityId}", testCollectionId, testEntityId))
                .andExpect(status().isCreated());

        verify(collectionService).addEntityToCollection(testUserId, testCollectionId, testEntityId);
    }

    @Test
    @DisplayName("DELETE /api/v1/collections/{id}/entities/{entityId} removes entity")
    void testRemoveEntityFromCollection() throws Exception {
        mockMvc.perform(delete("/api/v1/collections/{id}/entities/{entityId}", testCollectionId, testEntityId))
                .andExpect(status().isNoContent());

        verify(collectionService).removeEntityFromCollection(testUserId, testCollectionId, testEntityId);
    }

    @Test
    @DisplayName("DELETE /api/v1/collections/{id} deletes collection")
    void testDeleteCollection() throws Exception {
        mockMvc.perform(delete("/api/v1/collections/{id}", testCollectionId))
                .andExpect(status().isNoContent());

        verify(collectionService).deleteCollection(testUserId, testCollectionId);
    }

    @Test
    @DisplayName("GET /api/v1/entities/{entityId}/collections returns collection IDs")
    void testGetCollectionIdsForEntity() throws Exception {
        when(collectionService.getCollectionIdsForEntity(testUserId, testEntityId))
                .thenReturn(List.of(testCollectionId));

        mockMvc.perform(get("/api/v1/entities/{entityId}/collections", testEntityId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0]").value(testCollectionId.toString()));
    }
}
