package com.latyr.api.service;

import com.google.cloud.storage.Bucket;
import com.google.firebase.FirebaseApp;
import com.google.firebase.cloud.StorageClient;
import com.latyr.api.adapter.AssetStorage;
import com.latyr.api.adapter.ThumbnailStorage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.UUID;

@Service
public class FirebaseStorageService implements AssetStorage, ThumbnailStorage {

    private static final Logger log = LoggerFactory.getLogger(FirebaseStorageService.class);

    @Value("${firebase.storage.bucket-name:}")
    private String bucketName;

    private final WebClient webClient;

    public FirebaseStorageService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024))
                .build();
    }

    @Override
    public String uploadAssetFromUrl(String sourceUrl, String targetFolder, String fileName) {
        if (sourceUrl == null || sourceUrl.isBlank()) {
            return null;
        }

        if (bucketName == null || bucketName.isBlank()) {
            log.info("Storage bucket not configured (local dev); skipping cloud asset upload for {}/{}", targetFolder, fileName);
            return null;
        }

        if (FirebaseApp.getApps().isEmpty()) {
            log.info("Firebase App not initialized; skipping cloud asset upload for {}/{}", targetFolder, fileName);
            return null;
        }

        try {
            log.info("Downloading asset from URL: {}", sourceUrl);
            byte[] imageBytes = webClient.get()
                    .uri(sourceUrl)
                    .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                    .retrieve()
                    .bodyToMono(byte[].class)
                    .block(Duration.ofSeconds(15));

            if (imageBytes == null || imageBytes.length == 0) {
                log.warn("Empty asset downloaded from URL: {}", sourceUrl);
                return null;
            }

            Bucket bucket = StorageClient.getInstance().bucket(bucketName.trim());
            if (bucket == null) {
                log.warn("Bucket '{}' not found on Firebase Storage", bucketName);
                return null;
            }

            String cleanFolder = targetFolder.replaceAll("^/+", "").replaceAll("/+$", "");
            String objectName = cleanFolder.isEmpty() ? fileName : cleanFolder + "/" + fileName;

            String contentType = fileName.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";
            bucket.create(objectName, imageBytes, contentType);
            log.info("Successfully uploaded asset to Firebase Storage: {}", objectName);

            String encodedPath = URLEncoder.encode(objectName, StandardCharsets.UTF_8);
            String actualBucket = bucket.getName();
            return String.format("https://firebasestorage.googleapis.com/v0/b/%s/o/%s?alt=media", actualBucket, encodedPath);

        } catch (Exception e) {
            log.warn("Failed to upload asset to Firebase Storage ({}/{}): {}", targetFolder, fileName, e.getMessage());
            return null;
        }
    }

    @Override
    public String uploadImageFromUrl(String sourceUrl, UUID captureId) {
        if (sourceUrl == null || sourceUrl.isBlank()) {
            return null;
        }
        String permanentUrl = uploadAssetFromUrl(sourceUrl, "captures/" + captureId, "thumbnail.jpg");
        return permanentUrl != null ? permanentUrl : sourceUrl;
    }
}
