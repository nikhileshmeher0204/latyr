package com.latyr.latyr_api.exception;

import org.springframework.http.HttpStatus;
import java.util.Map;

public class QuotaExceededException extends LatyrException {

    public QuotaExceededException(String message, Map<String, Object> details) {
        super(message, "QUOTA_EXCEEDED", HttpStatus.PAYMENT_REQUIRED, details);
    }
}
