package com.latyr.api.adapter.storage;

/**
 * Decoupled facade for static asset storage and CDN URL resolution.
 * 
 * Complies with AGENTS.md Principle 6 (External Adapter Facades & Zero-Coupling Rule).
 * Allows seamlessly switching between Firebase Hosting, Cloudflare R2, AWS S3,
 * or self-hosted CDN without modifying domain enrichers or orchestration logic.
 */
public interface AssetStorageProvider {

    /**
     * Resolves the full CDN URL for a given relative asset path.
     * 
     * @param relativePath e.g. "netflix.svg" or "icons/streaming/netflix.svg"
     * @return fully qualified HTTPS CDN URL
     */
    String resolveAssetUrl(String relativePath);

    /**
     * Returns the configured base CDN URL.
     */
    String getBaseUrl();
}
