package com.latyr.api;

import com.latyr.api.domain.model.ExtractedEntity;
import com.latyr.api.domain.model.UserCollection;
import com.latyr.api.dto.CreateCollectionRequest;
import com.latyr.api.dto.UpdateCollectionRequest;
import com.latyr.api.dto.UserCollectionResponse;
import com.latyr.api.exception.LatyrException;
import com.latyr.api.mapper.ExtractedEntityMapper;
import com.latyr.api.mapper.UserCollectionMapper;
import com.latyr.api.service.UserCollectionServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserCollectionServiceTest {

    @Mock
    private UserCollectionMapper userCollectionMapper;

    @Mock
    private ExtractedEntityMapper extractedEntityMapper;

    @InjectMocks
    private UserCollectionServiceImpl userCollectionService;

    private UUID userId;
    private UUID collectionId;
    private UUID entityId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        collectionId = UUID.randomUUID();
        entityId = UUID.randomUUID();
    }

    @Test
    @DisplayName("getUserCollections returns summaries with artwork preview URLs and item count")
    void testGetUserCollections() {
        UserCollection col = new UserCollection();
        col.setId(collectionId);
        col.setUserId(userId);
        col.setName("Weekend Watchlist");
        col.setItemCount(3);
        col.setPreviewArtworkUrls(List.of("https://example.com/poster1.jpg", "https://example.com/poster2.jpg"));
        col.setCreatedAt(Instant.now());
        col.setUpdatedAt(Instant.now());

        when(userCollectionMapper.findSummariesByUserId(userId)).thenReturn(List.of(col));

        List<UserCollectionResponse> result = userCollectionService.getUserCollections(userId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).name()).isEqualTo("Weekend Watchlist");
        assertThat(result.get(0).itemCount()).isEqualTo(3);
        assertThat(result.get(0).previewArtworkUrls()).hasSize(2);
    }

    @Test
    @DisplayName("createCollection persists and returns created collection")
    void testCreateCollection() {
        CreateCollectionRequest request = new CreateCollectionRequest(
                "AI Stack",
                "Self-hosted developer tools",
                "folder_fill",
                "#28543A"
        );

        UserCollection saved = new UserCollection();
        saved.setId(collectionId);
        saved.setUserId(userId);
        saved.setName("AI Stack");
        saved.setDescription("Self-hosted developer tools");
        saved.setIcon("folder_fill");
        saved.setColorHex("#28543A");
        saved.setItemCount(0);
        saved.setCreatedAt(Instant.now());
        saved.setUpdatedAt(Instant.now());

        when(userCollectionMapper.insert(any(UserCollection.class))).thenReturn(1);
        when(userCollectionMapper.findSummaryByIdAndUserId(any(UUID.class), eq(userId)))
                .thenReturn(Optional.of(saved));

        UserCollectionResponse response = userCollectionService.createCollection(userId, request);

        assertThat(response.name()).isEqualTo("AI Stack");
        assertThat(response.description()).isEqualTo("Self-hosted developer tools");
        verify(userCollectionMapper).insert(any(UserCollection.class));
    }

    @Test
    @DisplayName("addEntityToCollection verifies ownership and adds entity association")
    void testAddEntityToCollection() {
        UserCollection col = new UserCollection();
        col.setId(collectionId);
        col.setUserId(userId);

        ExtractedEntity entity = new ExtractedEntity();
        entity.setId(entityId);

        when(userCollectionMapper.findByIdAndUserId(collectionId, userId)).thenReturn(Optional.of(col));
        when(extractedEntityMapper.findById(entityId)).thenReturn(Optional.of(entity));
        when(userCollectionMapper.getNextItemOrder(collectionId)).thenReturn(2);
        when(userCollectionMapper.findById(collectionId)).thenReturn(Optional.of(col));

        userCollectionService.addEntityToCollection(userId, collectionId, entityId);

        verify(userCollectionMapper).insertEntityAssociation(collectionId, entityId, 2);
        verify(userCollectionMapper).update(col);
    }

    @Test
    @DisplayName("addEntityToCollection throws 404 when collection not found")
    void testAddEntityToCollectionNotFound() {
        when(userCollectionMapper.findByIdAndUserId(collectionId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userCollectionService.addEntityToCollection(userId, collectionId, entityId))
                .isInstanceOf(LatyrException.class)
                .hasMessageContaining("Collection not found");
    }

    @Test
    @DisplayName("removeEntityFromCollection removes association and updates timestamp")
    void testRemoveEntityFromCollection() {
        UserCollection col = new UserCollection();
        col.setId(collectionId);
        col.setUserId(userId);

        when(userCollectionMapper.findByIdAndUserId(collectionId, userId)).thenReturn(Optional.of(col));
        when(userCollectionMapper.findById(collectionId)).thenReturn(Optional.of(col));

        userCollectionService.removeEntityFromCollection(userId, collectionId, entityId);

        verify(userCollectionMapper).deleteEntityAssociation(collectionId, entityId);
        verify(userCollectionMapper).update(col);
    }

    @Test
    @DisplayName("deleteCollection removes collection for owner")
    void testDeleteCollection() {
        UserCollection col = new UserCollection();
        col.setId(collectionId);
        col.setUserId(userId);

        when(userCollectionMapper.findByIdAndUserId(collectionId, userId)).thenReturn(Optional.of(col));

        userCollectionService.deleteCollection(userId, collectionId);

        verify(userCollectionMapper).deleteByIdAndUserId(collectionId, userId);
    }
}
