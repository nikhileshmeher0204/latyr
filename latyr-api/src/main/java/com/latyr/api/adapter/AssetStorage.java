package com.latyr.api.adapter;

/**
 * Common facade for uploading assets into cloud bucket storage.
 */
public interface AssetStorage {

    /**
     * Downloads an asset from the given source URL and stores it in the configured bucket
     * at {targetFolder}/{fileName}.
     *
     * @param sourceUrl   URL of the source asset to fetch
     * @param targetFolder Target bucket directory (e.g. "captures/thumbnails", "collections/covers")
     * @param fileName    Target filename (e.g. "uuid.jpg")
     * @return Permanent public URL of the uploaded asset, or null if storage is unconfigured / failed.
     */
    String uploadAssetFromUrl(String sourceUrl, String targetFolder, String fileName);
}
