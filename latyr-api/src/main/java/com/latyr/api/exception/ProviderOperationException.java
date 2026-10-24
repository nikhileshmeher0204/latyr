package com.latyr.api.exception;

import org.springframework.http.HttpStatus;

/** Provider adapters classify recovery without leaking vendor payloads into orchestration. */
public final class ProviderOperationException extends LatyrException {
    public enum Outcome { RETRYABLE, PERMANENT, AMBIGUOUS, UNSUPPORTED }
    private final Outcome outcome;

    public ProviderOperationException(String code, Outcome outcome) {
        super("Content processing is unavailable (" + code + ").", code, HttpStatus.BAD_GATEWAY);
        this.outcome = outcome;
    }

    public Outcome getOutcome() { return outcome; }
}
