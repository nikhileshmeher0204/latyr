package com.latyr.api.controller;

import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.dto.CaptureDetailResponse;
import com.latyr.api.dto.CaptureResponse;
import com.latyr.api.dto.CreateCaptureRequest;
import com.latyr.api.dto.PagedResponse;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.security.CurrentUser;
import com.latyr.api.service.CaptureService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/captures")
public class CaptureController {

    private final CaptureService captureService;

    public CaptureController(CaptureService captureService) {
        this.captureService = captureService;
    }

    @PostMapping
    public ResponseEntity<CaptureResponse> createUrlCapture(
            @CurrentUser AuthenticatedUser currentUser,
            @Valid @RequestBody CreateCaptureRequest request
    ) {
        CaptureResponse response = captureService.createUrlCapture(currentUser.getUserId(), request);
        if (CaptureStatus.COMPLETED.equals(response.status())) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<CaptureResponse> createImageCapture(
            @CurrentUser AuthenticatedUser currentUser,
            @RequestParam("file") MultipartFile file
    ) throws IOException {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        byte[] bytes = file.getBytes();
        CaptureResponse response = captureService.createImageCapture(currentUser.getUserId(), bytes, file.getOriginalFilename());

        if (CaptureStatus.COMPLETED.equals(response.status())) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
    }

    @GetMapping
    public ResponseEntity<PagedResponse<CaptureResponse>> getUserCaptures(
            @CurrentUser AuthenticatedUser currentUser,
            @RequestParam(name = "status", required = false) CaptureStatus status,
            @RequestParam(name = "category", required = false) String category,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {
        PagedResponse<CaptureResponse> response = captureService.getUserCaptures(
                currentUser.getUserId(), status, category, page, size
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CaptureDetailResponse> getCaptureDetail(
            @CurrentUser AuthenticatedUser currentUser,
            @PathVariable("id") UUID id
    ) {
        CaptureDetailResponse response = captureService.getCaptureDetail(currentUser.getUserId(), id);
        return ResponseEntity.ok(response);
    }
}
