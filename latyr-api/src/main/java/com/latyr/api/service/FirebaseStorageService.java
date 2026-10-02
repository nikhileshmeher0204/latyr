package com.latyr.api.service;

import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Bucket;
import com.google.firebase.FirebaseApp;
import com.google.firebase.cloud.StorageClient;
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
public class FirebaseStorageService {

    private static final Logger log = LoggerFactory.getLogger(FirebaseStorageService.class);

    @Value("${firebase.storage.bucket-name:}")
    private String bucketName;

    private final WebClient webClient;

    public FirebaseStorageService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024))
                .build();
    }

    /**
     * Downloads an image from the provided source URL and uploads it to Firebase Storage.
     * Returns the permanent public access URL.
     * If Firebase Storage is not configured or upload fails, falls back gracefully to sourceUrl.
     */
    public String uploadImageFromUrl(String sourceUrl, UUID captureId) {
        if (sourceUrl == null || sourceUrl.isBlank()) {
            return null;
        }

        if (FirebaseApp.getApps().isEmpty()) {
            log.info("Firebase App not initialized; returning source URL as thumbnail fallback: {}", sourceUrl);
            return sourceUrl;
        }

        try {
            log.info("Downloading thumbnail image from URL: {}", sourceUrl);
            byte[] imageBytes = webClient.get()
                    .uri(sourceUrl)
                    .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                    .retrieve()
                    .bodyToMono(byte[].class)
                    .block(Duration.ofSeconds(15));

            if (imageBytes == null || imageBytes.length == 0) {
                log.warn("Empty image downloaded from URL: {}", sourceUrl);
                return sourceUrl;
            }

            Bucket bucket;
            if (bucketName != null && !bucketName.isBlank()) {
                bucket = StorageClient.getInstance().bucket(bucketName.trim());
            } else {
                bucket = StorageClient.getInstance().bucket();
            }

            if (bucket == null) {
                log.warn("No default bucket found on Firebase Storage; returning sourceUrl");
                return sourceUrl;
            }

            String objectName = "captures/" + captureId + "/thumbnail.jpg";
            bucket.create(objectName, imageBytes, "image/jpeg");
            log.info("Successfully uploaded thumbnail to Firebase Storage: {}", objectName);

            String encodedPath = URLEncoder.encode(objectName, StandardCharsets.UTF_8);
            String actualBucket = bucket.getName();
            return String.format("https://firebasestorage.googleapis.com/v0/b/%s/o/%s?alt=media", actualBucket, encodedPath);

        } catch (Exception e) {
            log.warn("Failed to upload image to Firebase Storage for capture {}: {}. Falling back to sourceUrl.", captureId, e.getMessage());
            return sourceUrl;
        }
    }
}
