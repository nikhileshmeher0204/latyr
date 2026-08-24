package com.latyr.api.service;

import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class UrlNormalizationService {

    private static final Set<String> TRACKING_PARAMS = Set.of(
            "igsh", "fbclid", "si", "ref", "ref_src", "feature", "context", "mibextid",
            "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
            "gclid", "dclid", "_hsenc", "_hsmi", "mc_cid", "mc_eid"
    );

    public String normalizeUrl(String rawUrl) {
        if (rawUrl == null || rawUrl.trim().isEmpty()) {
            throw new IllegalArgumentException("URL cannot be empty");
        }

        try {
            String trimmed = rawUrl.trim();
            URI uri = new URI(trimmed);

            String scheme = uri.getScheme() != null ? uri.getScheme().toLowerCase(Locale.ROOT) : "https";
            String host = uri.getHost() != null ? uri.getHost().toLowerCase(Locale.ROOT) : "";

            // Normalize host (strip www. prefix for consistent matching if desired, or keep uniform)
            if (host.startsWith("www.")) {
                host = host.substring(4);
            }

            // Normalize path
            String path = uri.getPath();
            if (path == null || path.isEmpty()) {
                path = "/";
            } else {
                path = path.replaceAll("/{2,}", "/"); // collapse duplicate slashes
                if (path.length() > 1 && path.endsWith("/")) {
                    path = path.substring(0, path.length() - 1); // strip trailing slash
                }
            }

            // Filter tracking query params and sort remaining
            String query = uri.getRawQuery();
            String normalizedQuery = "";
            if (query != null && !query.trim().isEmpty()) {
                Map<String, List<String>> paramMap = parseQuery(query);
                List<String> sortedKeys = new ArrayList<>(paramMap.keySet());
                Collections.sort(sortedKeys);

                StringBuilder queryBuilder = new StringBuilder();
                for (String key : sortedKeys) {
                    if (TRACKING_PARAMS.contains(key.toLowerCase(Locale.ROOT))) {
                        continue;
                    }
                    List<String> values = paramMap.get(key);
                    for (String value : values) {
                        if (queryBuilder.length() > 0) {
                            queryBuilder.append("&");
                        }
                        queryBuilder.append(URLEncoder.encode(key, StandardCharsets.UTF_8));
                        if (value != null && !value.isEmpty()) {
                            queryBuilder.append("=").append(URLEncoder.encode(value, StandardCharsets.UTF_8));
                        }
                    }
                }
                if (queryBuilder.length() > 0) {
                    normalizedQuery = "?" + queryBuilder;
                }
            }

            int port = uri.getPort();
            String portString = (port == -1 || (scheme.equals("http") && port == 80) || (scheme.equals("https") && port == 443))
                    ? "" : ":" + port;

            return scheme + "://" + host + portString + path + normalizedQuery;
        } catch (Exception e) {
            // Fallback to basic string cleaning if URI syntax fails
            String cleaned = rawUrl.trim().replaceAll("\\?.*$", "");
            if (cleaned.endsWith("/")) {
                cleaned = cleaned.substring(0, cleaned.length() - 1);
            }
            return cleaned;
        }
    }

    public String computeSha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    public String computeSha256(byte[] bytes) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(bytes);
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    public String getCanonicalUrlHash(String rawUrl) {
        String normalized = normalizeUrl(rawUrl);
        return computeSha256(normalized);
    }

    private Map<String, List<String>> parseQuery(String query) {
        Map<String, List<String>> map = new LinkedHashMap<>();
        String[] pairs = query.split("&");
        for (String pair : pairs) {
            int idx = pair.indexOf("=");
            String key = idx > 0 ? URLDecoder.decode(pair.substring(0, idx), StandardCharsets.UTF_8) : pair;
            String val = idx > 0 && pair.length() > idx + 1 ? URLDecoder.decode(pair.substring(idx + 1), StandardCharsets.UTF_8) : "";
            map.computeIfAbsent(key, k -> new ArrayList<>()).add(val);
        }
        return map;
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder hexString = new StringBuilder(2 * bytes.length);
        for (byte b : bytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) {
                hexString.append('0');
            }
            hexString.append(hex);
        }
        return hexString.toString();
    }
}
