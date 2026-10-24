package com.latyr.api.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.genai.Client;
import com.google.genai.types.HttpOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class GoogleGenAIConfig {

    private static final Logger log = LoggerFactory.getLogger(GoogleGenAIConfig.class);

    @Value("${google.genai.api-key:${GEMINI_API_KEY:}}")
    private String apiKey;

    @Value("${google.genai.project-id:${GCP_PROJECT_ID:}}")
    private String projectId;

    @Value("${google.genai.location:${GCP_LOCATION:us-central1}}")
    private String location;

    @Value("${firebase.config.path:${FIREBASE_CONFIG_PATH:}}")
    private String firebaseConfigPath;

    @Value("${google.genai.timeout-ms:90000}")
    private int timeoutMs = 90000;

    @Bean
    public GoogleCredentials googleCredentials() throws IOException {
        // Option 1: Try explicit file path from FIREBASE_CONFIG_PATH
        if (firebaseConfigPath != null && !firebaseConfigPath.trim().isEmpty()) {
            try (InputStream is = new FileInputStream(firebaseConfigPath.trim())) {
                log.info("Loading Google Credentials from FIREBASE_CONFIG_PATH: {}", firebaseConfigPath);
                return GoogleCredentials.fromStream(is)
                        .createScoped("https://www.googleapis.com/auth/cloud-platform");
            } catch (Exception e) {
                log.warn("Could not load credentials from FIREBASE_CONFIG_PATH: {}", e.getMessage());
            }
        }

        // Option 2: Try environment variable GOOGLE_APPLICATION_CREDENTIALS_JSON
        String credentialsJson = System.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON");
        if (credentialsJson != null && !credentialsJson.trim().isEmpty()) {
            log.info("Loading Google Credentials from GOOGLE_APPLICATION_CREDENTIALS_JSON environment variable");
            return GoogleCredentials.fromStream(new ByteArrayInputStream(credentialsJson.getBytes()))
                .createScoped("https://www.googleapis.com/auth/cloud-platform");
        }

        // Option 3: Fall back to Google Application Default Credentials (ADC)
        log.info("Loading Google Application Default Credentials (ADC)...");
        try {
            return GoogleCredentials.getApplicationDefault()
                    .createScoped("https://www.googleapis.com/auth/cloud-platform");
        } catch (Exception e) {
            log.warn("Application Default Credentials not found: {}. Using anonymous credentials.", e.getMessage());
            return GoogleCredentials.create(null);
        }
    }

    @Bean(destroyMethod = "close")
    public Client googleGenAiClient(GoogleCredentials credentials) {
        if (timeoutMs < 1000) throw new IllegalArgumentException("AI timeout must be at least one second");
        HttpOptions httpOptions = HttpOptions.builder().timeout(timeoutMs).build();
        if (apiKey != null && !apiKey.trim().isEmpty()) {
            log.info("Initializing Google GenAI SDK Client in Gemini Developer mode using API Key");
            return Client.builder().apiKey(apiKey.trim()).httpOptions(httpOptions).build();
        }

        String effectiveProjectId = null;

        // Auto-extract real Project ID from Service Account credentials
        if (credentials instanceof ServiceAccountCredentials sa && sa.getProjectId() != null && !sa.getProjectId().isEmpty()) {
            effectiveProjectId = sa.getProjectId();
            log.info("Extracted GCP Project ID from service account credentials: {}", effectiveProjectId);
        }

        if (effectiveProjectId == null || effectiveProjectId.trim().isEmpty()) {
            effectiveProjectId = projectId;
        }

        if (effectiveProjectId == null || effectiveProjectId.trim().isEmpty()) {
            effectiveProjectId = "latyr-prod";
        }

        log.info("Initializing Google GenAI SDK Client in Vertex AI mode (project: {}, location: {})", effectiveProjectId, location);
        Client.Builder builder = Client.builder()
                .vertexAI(true)
                .httpOptions(httpOptions)
                .project(effectiveProjectId)
                .location(location);

        if (credentials != null && credentials.getAuthenticationType() != null) {
            builder.credentials(credentials);
        }

        return builder.build();
    }
}
