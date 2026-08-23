package com.latyr.latyr_api.exception;

import org.springframework.http.HttpStatus;

public class ResourceNotFoundException extends LatyrException {

    public ResourceNotFoundException(String message) {
        super(message, "NOT_FOUND", HttpStatus.NOT_FOUND);
    }
}
