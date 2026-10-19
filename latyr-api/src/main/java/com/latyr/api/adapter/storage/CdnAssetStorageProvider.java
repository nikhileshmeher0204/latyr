package com.latyr.api.adapter.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Default CDN asset storage provider reading the CDN base URL dynamically
 * from environment configuration properties.
 */
@Component
public class CdnAssetStorageProvider implements AssetStorageProvider {

    private final String cdnBaseUrl;

    public CdnAssetStorageProvider(
        @Value("${latyr.assets.cdn-base-url:https://latyr-a5dfa.web.app/assets/icons/streaming/}") String cdnBaseUrl
    ) {
        String base = (cdnBaseUrl != null && !cdnBaseUrl.isBlank())
            ? cdnBaseUrl.trim()
            : "https://latyr-a5dfa.web.app/assets/icons/streaming/";
        this.cdnBaseUrl = base.endsWith("/") ? base : base + "/";
    }

    @Override
    public String resolveAssetUrl(String relativePath) {
        if (relativePath == null || relativePath.isBlank()) {
            return null;
        }
        if (relativePath.startsWith("http://") || relativePath.startsWith("https://")) {
            return relativePath;
        }
        String clean = relativePath.startsWith("/") ? relativePath.substring(1) : relativePath;
        return cdnBaseUrl + clean;
    }

    @Override
    public String getBaseUrl() {
        return cdnBaseUrl;
    }
}
