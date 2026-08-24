package com.latyr.api.exception;

import org.springframework.http.HttpStatus;

public class ExternalProviderException extends LatyrException {

    public ExternalProviderException(String providerName, String message) {
        super(providerName + " error: " + message, "PROVIDER_FAILED", HttpStatus.BAD_GATEWAY);
    }
}
