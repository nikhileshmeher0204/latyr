package com.latyr.api.service;

import com.latyr.api.domain.model.ExtractedEntity;
import com.latyr.api.domain.model.UserCollection;
import com.latyr.api.dto.CreateCollectionRequest;
import com.latyr.api.dto.ExtractedEntityResponse;
import com.latyr.api.dto.UpdateCollectionRequest;
import com.latyr.api.dto.UserCollectionResponse;
import com.latyr.api.exception.LatyrException;
import com.latyr.api.mapper.ExtractedEntityMapper;
import com.latyr.api.mapper.UserCollectionMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class UserCollectionServiceImpl implements UserCollectionService {

    private static final Logger log = LoggerFactory.getLogger(UserCollectionServiceImpl.class);

    private final UserCollectionMapper userCollectionMapper;
    private final ExtractedEntityMapper extractedEntityMapper;

    public UserCollectionServiceImpl(
            UserCollectionMapper userCollectionMapper,
            ExtractedEntityMapper extractedEntityMapper
    ) {
        this.userCollectionMapper = userCollectionMapper;
        this.extractedEntityMapper = extractedEntityMapper;
    }

    @Override
    public List<UserCollectionResponse> getUserCollections(UUID userId) {
        return userCollectionMapper.findSummariesByUserId(userId).stream()
                .map(UserCollectionResponse::fromModel)
                .toList();
    }

    @Override
    public UserCollectionResponse getCollectionById(UUID userId, UUID collectionId) {
        return userCollectionMapper.findSummaryByIdAndUserId(collectionId, userId)
                .map(UserCollectionResponse::fromModel)
                .orElseThrow(() -> new LatyrException(
                        "Collection not found: " + collectionId,
                        "COLLECTION_NOT_FOUND",
                        HttpStatus.NOT_FOUND
                ));
    }

    @Override
    @Transactional
    public UserCollectionResponse createCollection(UUID userId, CreateCollectionRequest request) {
        UserCollection collection = new UserCollection();
        collection.setId(UUID.randomUUID());
        collection.setUserId(userId);
        collection.setName(request.name().trim());
        collection.setDescription(request.description() != null ? request.description().trim() : null);
        collection.setIcon(request.icon() != null && !request.icon().isBlank() ? request.icon().trim() : "folder_fill");
        collection.setColorHex(request.colorHex() != null && !request.colorHex().isBlank() ? request.colorHex().trim() : "#28543A");
        collection.setPinned(false);
        collection.setCreatedAt(Instant.now());
        collection.setUpdatedAt(Instant.now());

        userCollectionMapper.insert(collection);
        log.info("Created user collection {} ('{}') for user {}", collection.getId(), collection.getName(), userId);

        return getCollectionById(userId, collection.getId());
    }

    @Override
    @Transactional
    public UserCollectionResponse updateCollection(UUID userId, UUID collectionId, UpdateCollectionRequest request) {
        UserCollection existing = userCollectionMapper.findByIdAndUserId(collectionId, userId)
                .orElseThrow(() -> new LatyrException(
                        "Collection not found: " + collectionId,
                        "COLLECTION_NOT_FOUND",
                        HttpStatus.NOT_FOUND
                ));

        if (request.name() != null && !request.name().isBlank()) {
            existing.setName(request.name().trim());
        }
        if (request.description() != null) {
            existing.setDescription(request.description().trim());
        }
        if (request.icon() != null && !request.icon().isBlank()) {
            existing.setIcon(request.icon().trim());
        }
        if (request.colorHex() != null && !request.colorHex().isBlank()) {
            existing.setColorHex(request.colorHex().trim());
        }
        if (request.isPinned() != null) {
            existing.setPinned(request.isPinned());
        }
        existing.setUpdatedAt(Instant.now());

        userCollectionMapper.update(existing);
        log.info("Updated collection {} for user {}", collectionId, userId);

        return getCollectionById(userId, collectionId);
    }

    @Override
    @Transactional
    public void deleteCollection(UUID userId, UUID collectionId) {
        UserCollection existing = userCollectionMapper.findByIdAndUserId(collectionId, userId)
                .orElseThrow(() -> new LatyrException(
                        "Collection not found: " + collectionId,
                        "COLLECTION_NOT_FOUND",
                        HttpStatus.NOT_FOUND
                ));

        userCollectionMapper.deleteByIdAndUserId(existing.getId(), userId);
        log.info("Deleted collection {} for user {}", collectionId, userId);
    }

    @Override
    @Transactional
    public void addEntityToCollection(UUID userId, UUID collectionId, UUID entityId) {
        userCollectionMapper.findByIdAndUserId(collectionId, userId)
                .orElseThrow(() -> new LatyrException(
                        "Collection not found: " + collectionId,
                        "COLLECTION_NOT_FOUND",
                        HttpStatus.NOT_FOUND
                ));

        extractedEntityMapper.findById(entityId)
                .orElseThrow(() -> new LatyrException(
                        "Extracted entity not found: " + entityId,
                        "ENTITY_NOT_FOUND",
                        HttpStatus.NOT_FOUND
                ));

        int nextOrder = userCollectionMapper.getNextItemOrder(collectionId);
        userCollectionMapper.insertEntityAssociation(collectionId, entityId, nextOrder);

        // Touch updated_at on collection
        UserCollection col = userCollectionMapper.findById(collectionId).orElse(null);
        if (col != null) {
            col.setUpdatedAt(Instant.now());
            userCollectionMapper.update(col);
        }
        log.info("Added entity {} to collection {} for user {}", entityId, collectionId, userId);
    }

    @Override
    @Transactional
    public void removeEntityFromCollection(UUID userId, UUID collectionId, UUID entityId) {
        userCollectionMapper.findByIdAndUserId(collectionId, userId)
                .orElseThrow(() -> new LatyrException(
                        "Collection not found: " + collectionId,
                        "COLLECTION_NOT_FOUND",
                        HttpStatus.NOT_FOUND
                ));

        userCollectionMapper.deleteEntityAssociation(collectionId, entityId);

        // Touch updated_at on collection
        UserCollection col = userCollectionMapper.findById(collectionId).orElse(null);
        if (col != null) {
            col.setUpdatedAt(Instant.now());
            userCollectionMapper.update(col);
        }
        log.info("Removed entity {} from collection {} for user {}", entityId, collectionId, userId);
    }

    @Override
    public List<ExtractedEntityResponse> getCollectionEntities(UUID userId, UUID collectionId) {
        userCollectionMapper.findByIdAndUserId(collectionId, userId)
                .orElseThrow(() -> new LatyrException(
                        "Collection not found: " + collectionId,
                        "COLLECTION_NOT_FOUND",
                        HttpStatus.NOT_FOUND
                ));

        return extractedEntityMapper.findByUserCollectionIdAndUserId(collectionId, userId).stream()
                .map(ExtractedEntityResponse::fromModel)
                .toList();
    }

    @Override
    public List<UUID> getCollectionIdsForEntity(UUID userId, UUID entityId) {
        return userCollectionMapper.findCollectionIdsForEntity(userId, entityId);
    }
}
