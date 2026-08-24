package com.latyr.api.dto;

import java.time.Instant;
import java.util.Map;

public record ErrorResponse(
    Instant timestamp,
    int status,
    String error,
    String message,
    String path,
    Map<String, Object> details
) {
    public ErrorResponse(int status, String error, String message, String path) {
        this(Instant.now(), status, error, message, path, Map.of());
    }

    public ErrorResponse(int status, String error, String message, String path, Map<String, Object> details) {
        this(Instant.now(), status, error, message, path, details != null ? details : Map.of());
    }
}
