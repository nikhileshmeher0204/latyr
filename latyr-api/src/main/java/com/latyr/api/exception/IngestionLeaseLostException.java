package com.latyr.api.exception;

import org.springframework.http.HttpStatus;

public class IngestionLeaseLostException extends LatyrException {
    public IngestionLeaseLostException() {
        super("Ingestion ownership expired or was replaced.", "INGESTION_LEASE_LOST", HttpStatus.CONFLICT);
    }
}
