package com.latyr.api.service;

import com.latyr.api.dto.CreateCollectionRequest;
import com.latyr.api.dto.ExtractedEntityResponse;
import com.latyr.api.dto.UpdateCollectionRequest;
import com.latyr.api.dto.UserCollectionResponse;

import java.util.List;
import java.util.UUID;

public interface UserCollectionService {

    List<UserCollectionResponse> getUserCollections(UUID userId);

    UserCollectionResponse getCollectionById(UUID userId, UUID collectionId);

    UserCollectionResponse createCollection(UUID userId, CreateCollectionRequest request);

    UserCollectionResponse updateCollection(UUID userId, UUID collectionId, UpdateCollectionRequest request);

    void deleteCollection(UUID userId, UUID collectionId);

    void addEntityToCollection(UUID userId, UUID collectionId, UUID entityId);

    void removeEntityFromCollection(UUID userId, UUID collectionId, UUID entityId);

    List<ExtractedEntityResponse> getCollectionEntities(UUID userId, UUID collectionId);

    List<UUID> getCollectionIdsForEntity(UUID userId, UUID entityId);
}
