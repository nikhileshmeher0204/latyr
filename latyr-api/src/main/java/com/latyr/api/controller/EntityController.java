package com.latyr.api.controller;

import com.latyr.api.dto.ExtractedEntityResponse;
import com.latyr.api.dto.UpdateEntityRequest;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.security.CurrentUser;
import com.latyr.api.service.CaptureService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/entities")
public class EntityController {

    private final CaptureService captureService;

    public EntityController(CaptureService captureService) {
        this.captureService = captureService;
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ExtractedEntityResponse> updateEntity(
            @CurrentUser AuthenticatedUser currentUser,
            @PathVariable("id") UUID id,
            @Valid @RequestBody UpdateEntityRequest request
    ) {
        ExtractedEntityResponse response = captureService.updateEntity(currentUser.getUserId(), id, request);
        return ResponseEntity.ok(response);
    }
}
