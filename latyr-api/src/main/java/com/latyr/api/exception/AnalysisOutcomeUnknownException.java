package com.latyr.api.exception;

import org.springframework.http.HttpStatus;

public class AnalysisOutcomeUnknownException extends LatyrException {
    public AnalysisOutcomeUnknownException() {
        super("The previous analysis outcome is unknown; automatic analysis replay is disabled.",
            "AMBIGUOUS_ANALYSIS", HttpStatus.CONFLICT);
    }
}
