package com.latyr.api.domain.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

import java.util.Locale;

/**
 * Categorization of entertainment watch providers (powered by JustWatch / TMDB).
 * Supports Subscription (SVOD), Rental (TVOD), Digital Purchase (EST), and Free (AVOD).
 */
public enum WatchProviderCategory {
    FLATRATE("subscription", "Subscription"),
    RENT("rent", "Rent"),
    BUY("buy", "Buy"),
    FREE("free", "Free");

    private final String code;
    private final String displayName;

    WatchProviderCategory(String code, String displayName) {
        this.code = code;
        this.displayName = displayName;
    }

    @JsonValue
    public String getCode() {
        return code;
    }

    public String getDisplayName() {
        return displayName;
    }

    @JsonCreator
    public static WatchProviderCategory fromCode(String code) {
        if (code == null || code.isBlank()) return FLATRATE;
        String normalized = code.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case "subscription", "flatrate", "stream" -> FLATRATE;
            case "rent" -> RENT;
            case "buy", "purchase" -> BUY;
            case "free", "ads" -> FREE;
            default -> FLATRATE;
        };
    }
}
