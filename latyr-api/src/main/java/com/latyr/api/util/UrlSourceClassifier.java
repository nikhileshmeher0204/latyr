package com.latyr.api.util;

import com.latyr.api.domain.enums.SourceType;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Production-grade RFC-3986 compliant URL classifier and normalizer.
 * Extracts raw URLs from dirty share text, strips tracking blobs,
 * and identifies the media source type.
 */
public final class UrlSourceClassifier {

    private static final Pattern URL_PATTERN = Pattern.compile(
            "https?://[a-zA-Z0-9.-]+(?:/[^\\s]*)?",
            Pattern.CASE_INSENSITIVE
    );

    // Common tracking parameters appended by mobile share sheets and analytics
    private static final Set<String> TRACKING_PARAMS = new HashSet<>(Arrays.asList(
            "igsh", "si", "feature", "utm_source", "utm_medium", "utm_campaign",
            "utm_term", "utm_content", "fbclid", "gclid", "ref", "ref_src",
            "source", "campaign", "app_data"
    ));

    private UrlSourceClassifier() {}

    /**
     * Extracts the first valid HTTP/HTTPS URL from arbitrary text
     * (e.g. Android/iOS share sheet commentary).
     */
    public static String extractFirstUrl(String rawText) {
        if (rawText == null || rawText.isBlank()) {
            return null;
        }
        Matcher matcher = URL_PATTERN.matcher(rawText);
        if (matcher.find()) {
            String candidate = matcher.group();
            // Trim any trailing punctuation often caught in share messages (e.g. '.', ')', '!')
            while (candidate.endsWith(".") || candidate.endsWith(",") || candidate.endsWith("!") || candidate.endsWith("?")) {
                candidate = candidate.substring(0, candidate.length() - 1);
            }
            return candidate;
        }
        return rawText.trim();
    }

    /**
     * Normalizes a URL by stripping tracking query parameters, lowercasing the scheme/host,
     * and preserving canonical video IDs and paths.
     */
    public static String normalizeUrl(String rawTextOrUrl) {
        String urlString = extractFirstUrl(rawTextOrUrl);
        if (urlString == null || urlString.isBlank()) {
            return "";
        }

        try {
            URI uri = URI.create(urlString);
            String scheme = uri.getScheme() != null ? uri.getScheme().toLowerCase(Locale.ROOT) : "https";
            String host = uri.getHost() != null ? uri.getHost().toLowerCase(Locale.ROOT) : "";
            if (host.startsWith("www.")) {
                host = host.substring(4);
            }

            String path = uri.getPath() != null ? uri.getPath() : "";
            // Ensure no double trailing slash if length > 1
            if (path.length() > 1 && path.endsWith("/")) {
                path = path.substring(0, path.length() - 1);
            }

            String rawQuery = uri.getRawQuery();
            StringBuilder cleanQuery = new StringBuilder();

            if (rawQuery != null && !rawQuery.isBlank()) {
                String[] pairs = rawQuery.split("&");
                for (String pair : pairs) {
                    if (pair.isBlank()) continue;
                    int idx = pair.indexOf('=');
                    String key = idx > 0 ? pair.substring(0, idx) : pair;
                    String decodedKey = URLDecoder.decode(key, StandardCharsets.UTF_8).toLowerCase(Locale.ROOT);

                    if (!TRACKING_PARAMS.contains(decodedKey)) {
                        if (cleanQuery.length() > 0) {
                            cleanQuery.append('&');
                        }
                        cleanQuery.append(pair);
                    }
                }
            }

            StringBuilder normalized = new StringBuilder();
            normalized.append(scheme).append("://").append(host).append(path);
            if (cleanQuery.length() > 0) {
                normalized.append('?').append(cleanQuery);
            }

            return normalized.toString();
        } catch (Exception e) {
            // Fallback to trimmed original on parsing failure
            return urlString;
        }
    }

    /**
     * Classifies a URL or shared text into its corresponding SourceType.
     */
    public static SourceType classify(String rawTextOrUrl) {
        if (rawTextOrUrl == null || rawTextOrUrl.isBlank()) {
            return SourceType.WEB_URL;
        }

        String urlString = extractFirstUrl(rawTextOrUrl);
        if (urlString == null || urlString.isBlank()) {
            return SourceType.WEB_URL;
        }

        try {
            URI uri = URI.create(urlString);
            String host = uri.getHost();
            if (host == null) {
                return SourceType.WEB_URL;
            }

            host = host.toLowerCase(Locale.ROOT);
            if (host.startsWith("www.")) {
                host = host.substring(4);
            }

            String path = uri.getPath() != null ? uri.getPath().toLowerCase(Locale.ROOT) : "";

            // 1. Instagram
            if (host.equals("instagram.com") || host.equals("instagr.am")) {
                // Per requirement: Instagram posts and reels are both treated under INSTAGRAM_REEL for now
                return SourceType.INSTAGRAM_REEL;
            }

            // 2. YouTube
            if (host.equals("youtube.com") || host.equals("m.youtube.com")) {
                if (path.startsWith("/shorts/") || path.equals("/shorts")) {
                    return SourceType.YOUTUBE_SHORT;
                }
                return SourceType.YOUTUBE_VIDEO;
            }

            if (host.equals("youtu.be")) {
                if (path.startsWith("/shorts/")) {
                    return SourceType.YOUTUBE_SHORT;
                }
                return SourceType.YOUTUBE_VIDEO;
            }

            // 3. Fallback to generic web URL
            return SourceType.WEB_URL;
        } catch (Exception e) {
            return SourceType.WEB_URL;
        }
    }
}
