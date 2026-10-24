package com.latyr.api.event;

import java.util.UUID;

/**
 * Reusable event published when an external asset (image, thumbnail, avatar)
 * needs to be fetched and stored in permanent Cloud Storage.
 */
public record AssetUploadRequestedEvent(
        String sourceUrl,
        String targetFolder,
        String fileName,
        AssetType assetType,
        UUID referenceId
) {
    public enum AssetType {
        CAPTURE_THUMBNAIL,
        COLLECTION_COVER,
        USER_AVATAR
    }
}
