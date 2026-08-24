package com.latyr.api.domain.enums;

import com.fasterxml.jackson.annotation.JsonCreator;

import java.util.Locale;

public enum Language {
    ENGLISH,
    HINGLISH,
    HINDI,
    ORIGINAL;

    @JsonCreator
    public static Language fromString(String value) {
        if (value == null || value.trim().isEmpty()) {
            return ENGLISH;
        }
        String normalized = value.trim().toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "EN", "ENGLISH" -> ENGLISH;
            case "HI", "HINDI" -> HINDI;
            case "HINGLISH" -> HINGLISH;
            case "ORIGINAL", "ORIG" -> ORIGINAL;
            default -> {
                for (Language lang : values()) {
                    if (lang.name().equalsIgnoreCase(normalized)) {
                        yield lang;
                    }
                }
                yield ENGLISH;
            }
        };
    }
}
