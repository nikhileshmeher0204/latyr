package com.latyr.api.controller;

import com.latyr.api.dto.CreateCollectionRequest;
import com.latyr.api.dto.ExtractedEntityResponse;
import com.latyr.api.dto.UpdateCollectionRequest;
import com.latyr.api.dto.UserCollectionResponse;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.security.CurrentUser;
import com.latyr.api.service.UserCollectionService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class UserCollectionController {

    private final UserCollectionService collectionService;

    public UserCollectionController(UserCollectionService collectionService) {
        this.collectionService = collectionService;
    }

    @GetMapping("/collections")
    public ResponseEntity<List<UserCollectionResponse>> getUserCollections(
            @CurrentUser AuthenticatedUser currentUser
    ) {
        return ResponseEntity.ok(collectionService.getUserCollections(currentUser.getUserId()));
    }

    @GetMapping("/collections/{id}")
    public ResponseEntity<UserCollectionResponse> getCollectionById(
            @PathVariable("id") UUID id,
            @CurrentUser AuthenticatedUser currentUser
    ) {
        return ResponseEntity.ok(collectionService.getCollectionById(currentUser.getUserId(), id));
    }

    @PostMapping("/collections")
    public ResponseEntity<UserCollectionResponse> createCollection(
            @CurrentUser AuthenticatedUser currentUser,
            @Valid @RequestBody CreateCollectionRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(collectionService.createCollection(currentUser.getUserId(), request));
    }

    @PatchMapping("/collections/{id}")
    public ResponseEntity<UserCollectionResponse> updateCollection(
            @PathVariable("id") UUID id,
            @CurrentUser AuthenticatedUser currentUser,
            @Valid @RequestBody UpdateCollectionRequest request
    ) {
        return ResponseEntity.ok(collectionService.updateCollection(currentUser.getUserId(), id, request));
    }

    @DeleteMapping("/collections/{id}")
    public ResponseEntity<Void> deleteCollection(
            @PathVariable("id") UUID id,
            @CurrentUser AuthenticatedUser currentUser
    ) {
        collectionService.deleteCollection(currentUser.getUserId(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/collections/{id}/entities")
    public ResponseEntity<List<ExtractedEntityResponse>> getCollectionEntities(
            @PathVariable("id") UUID id,
            @CurrentUser AuthenticatedUser currentUser
    ) {
        return ResponseEntity.ok(collectionService.getCollectionEntities(currentUser.getUserId(), id));
    }

    @PostMapping("/collections/{id}/entities/{entityId}")
    public ResponseEntity<Void> addEntityToCollection(
            @PathVariable("id") UUID id,
            @PathVariable("entityId") UUID entityId,
            @CurrentUser AuthenticatedUser currentUser
    ) {
        collectionService.addEntityToCollection(currentUser.getUserId(), id, entityId);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/collections/{id}/entities/{entityId}")
    public ResponseEntity<Void> removeEntityFromCollection(
            @PathVariable("id") UUID id,
            @PathVariable("entityId") UUID entityId,
            @CurrentUser AuthenticatedUser currentUser
    ) {
        collectionService.removeEntityFromCollection(currentUser.getUserId(), id, entityId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/entities/{entityId}/collections")
    public ResponseEntity<List<UUID>> getCollectionIdsForEntity(
            @PathVariable("entityId") UUID entityId,
            @CurrentUser AuthenticatedUser currentUser
    ) {
        return ResponseEntity.ok(collectionService.getCollectionIdsForEntity(currentUser.getUserId(), entityId));
    }
}
