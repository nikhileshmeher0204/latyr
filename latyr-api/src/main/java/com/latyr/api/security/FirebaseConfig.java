package com.latyr.api.security;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

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
            FirebaseOptions options;
            if (firebaseConfigPath != null && !firebaseConfigPath.trim().isEmpty()) {
                log.info("Initializing Firebase App from credentials file: {}", firebaseConfigPath);
                try (InputStream serviceAccount = new FileInputStream(firebaseConfigPath)) {
                    options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();
                    FirebaseApp.initializeApp(options);
                }
            } else {
                log.info("Initializing Firebase App using Google Application Default Credentials (ADC)...");
                options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.getApplicationDefault())
                        .build();
                FirebaseApp.initializeApp(options);
            }

            log.info("Firebase App initialized successfully.");
        } catch (Exception e) {
            log.warn("Firebase Admin SDK not initialized: {}. Ensure FIREBASE_CONFIG_PATH or GOOGLE_APPLICATION_CREDENTIALS is set.", e.getMessage());
        }
    }
}
