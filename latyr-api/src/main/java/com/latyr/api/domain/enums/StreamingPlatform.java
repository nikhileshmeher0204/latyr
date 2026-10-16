package com.latyr.api.domain.enums;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/**
 * Standardized Streaming Platforms for dynamic intent attribution and deep linking.
 */
public enum StreamingPlatform {
    NETFLIX("Netflix", "#E50914", "https://assets.nflxext.com/ffe/siteui/common/icons/nficon2016.ico"),
    PRIME_VIDEO("Prime Video", "#00A8E1", "https://m.media-amazon.com/images/G/01/digital/video/web/favicon-32x32.png"),
    APPLE_TV("Apple TV", "#FFFFFF", "https://tv.apple.com/favicon.ico"),
    DISNEY_HOTSTAR("JioHotstar", "#14805E", "https://www.hotstar.com/favicon.ico"),
    SONY_LIV("Sony LIV", "#003399", "https://www.sonyliv.com/favicon.ico"),
    ZEE5("ZEE5", "#7B1FA2", "https://www.zee5.com/favicon.ico"),
    YOUTUBE("YouTube", "#FF0000", "https://www.youtube.com/favicon.ico"),
    THEATRICAL("In Theaters", "#D4AF37", null),
    OTHER("Stream", "#2C2C2E", null);

    private final String displayName;
    private final String brandColorHex;
    private final String iconUrl;

    StreamingPlatform(String displayName, String brandColorHex, String iconUrl) {
        this.displayName = displayName;
        this.brandColorHex = brandColorHex;
        this.iconUrl = iconUrl;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getBrandColorHex() {
        return brandColorHex;
    }

    public String getIconUrl() {
        return iconUrl;
    }

    public static StreamingPlatform parse(String raw) {
        if (raw == null || raw.isBlank()) return OTHER;
        String s = raw.trim().toLowerCase();
        if (s.contains("netflix")) return NETFLIX;
        if (s.contains("prime") || s.contains("amazon")) return PRIME_VIDEO;
        if (s.contains("apple")) return APPLE_TV;
        if (s.contains("hotstar") || s.contains("disney")) return DISNEY_HOTSTAR;
        if (s.contains("sonyliv") || s.contains("sony")) return SONY_LIV;
        if (s.contains("zee")) return ZEE5;
        if (s.contains("youtube")) return YOUTUBE;
        if (s.contains("theater") || s.contains("cinema")) return THEATRICAL;
        return OTHER;
    }

    public String generateSearchUrl(String title) {
        String encoded = URLEncoder.encode(title != null ? title : "", StandardCharsets.UTF_8);
        return switch (this) {
            case NETFLIX -> "https://www.netflix.com/search?q=" + encoded;
            case PRIME_VIDEO -> "https://www.amazon.com/s?k=" + encoded + "&i=instant-video";
            case APPLE_TV -> "https://tv.apple.com/search?term=" + encoded;
            case DISNEY_HOTSTAR -> "https://www.hotstar.com/in/explore?search_query=" + encoded;
            case SONY_LIV -> "https://www.sonyliv.com/search/" + encoded;
            case ZEE5 -> "https://www.zee5.com/search?q=" + encoded;
            case YOUTUBE -> "https://www.youtube.com/results?search_query=" + encoded;
            default -> "https://www.google.com/search?q=watch+" + encoded;
        };
    }
}
