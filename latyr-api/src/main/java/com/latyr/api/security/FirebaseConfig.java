package com.latyr.api.security;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;

import jakarta.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${firebase.config.path:}")
    private String firebaseConfigPath;

    @PostConstruct
    public void initialize() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }

        try {
            FirebaseOptions options = null;

            // Option 1: Try explicit file path from FIREBASE_CONFIG_PATH
            if (firebaseConfigPath != null && !firebaseConfigPath.trim().isEmpty()) {
                log.info("Initializing Firebase App from credentials path: {}", firebaseConfigPath);
                try (InputStream is = new FileInputStream(firebaseConfigPath.trim())) {
                    options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(is))
                            .build();
                } catch (Exception e) {
                    log.warn("Could not load credentials from FIREBASE_CONFIG_PATH: {}", e.getMessage());
                }
            }

            // Option 2: Try classpath resource firebase-service-account.json
            if (options == null) {
                Resource resource = new ClassPathResource("firebase-service-account.json");
                if (resource.exists()) {
                    log.info("Initializing Firebase App from classpath: firebase-service-account.json");
                    try (InputStream is = resource.getInputStream()) {
                        options = FirebaseOptions.builder()
                                .setCredentials(GoogleCredentials.fromStream(is))
                                .build();
                    } catch (Exception e) {
                        log.warn("Could not load credentials from classpath resource: {}", e.getMessage());
                    }
                }
            }

            // Option 3: Fall back to Google Application Default Credentials (ADC)
            if (options == null) {
                log.info("Initializing Firebase App using Google Application Default Credentials (ADC)...");
                options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.getApplicationDefault())
                        .build();
            }

            FirebaseApp.initializeApp(options);
            log.info("Firebase App initialized successfully.");
        } catch (Exception e) {
            log.warn("Firebase Admin SDK not initialized: {}. Ensure FIREBASE_CONFIG_PATH or firebase-service-account.json is provided.", e.getMessage());
        }
    }
}
