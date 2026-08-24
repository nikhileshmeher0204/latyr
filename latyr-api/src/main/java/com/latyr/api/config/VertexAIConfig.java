package com.latyr.api.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.genai.Client;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class VertexAIConfig {

    private static final Logger log = LoggerFactory.getLogger(VertexAIConfig.class);

    @Value("${google.cloud.project-id:${GCP_PROJECT_ID:}}")
    private String projectId;

    @Value("${google.cloud.location:${GCP_LOCATION:us-central1}}")
    private String location;

    @Value("${firebase.config.path:${FIREBASE_CONFIG_PATH:}}")
    private String firebaseConfigPath;

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

        // Option 2: Try classpath resource firebase-service-account.json
        Resource resource = new ClassPathResource("firebase-service-account.json");
        if (resource.exists()) {
            try (InputStream is = resource.getInputStream()) {
                log.info("Loading Google Credentials from classpath: firebase-service-account.json");
                return GoogleCredentials.fromStream(is)
                        .createScoped("https://www.googleapis.com/auth/cloud-platform");
            } catch (Exception e) {
                log.warn("Could not load credentials from classpath resource: {}", e.getMessage());
            }
        }

        // Option 3: Try environment variable GOOGLE_APPLICATION_CREDENTIALS_JSON
        String credentialsJson = System.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON");
        if (credentialsJson != null && !credentialsJson.trim().isEmpty()) {
            log.info("Loading Google Credentials from GOOGLE_APPLICATION_CREDENTIALS_JSON environment variable");
            return GoogleCredentials.fromStream(new ByteArrayInputStream(credentialsJson.getBytes()))
                    .createScoped("https://www.googleapis.com/auth/cloud-platform");
        }

        // Option 4: Fall back to Google Application Default Credentials (ADC)
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
    public Client genAiClient(GoogleCredentials credentials) {
        String effectiveProjectId = projectId;
        if ((effectiveProjectId == null || effectiveProjectId.trim().isEmpty()) && credentials instanceof ServiceAccountCredentials sa) {
            if (sa.getProjectId() != null && !sa.getProjectId().isEmpty()) {
                effectiveProjectId = sa.getProjectId();
            }
        }
        if (effectiveProjectId == null || effectiveProjectId.trim().isEmpty()) {
            effectiveProjectId = "latyr-prod";
        }

        log.info("Initializing Google GenAI SDK Client with Vertex AI mode (project: {}, location: {})", effectiveProjectId, location);
        Client.Builder builder = Client.builder()
                .vertexAI(true)
                .project(effectiveProjectId)
                .location(location);

        if (credentials != null && credentials.getAuthenticationType() != null) {
            builder.credentials(credentials);
        }

        return builder.build();
    }
}
