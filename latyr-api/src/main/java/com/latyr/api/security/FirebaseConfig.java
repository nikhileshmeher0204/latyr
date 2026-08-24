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

    @Value("${firebase.auth.mock-enabled:false}")
    private boolean mockEnabled;

    @PostConstruct
    public void initialize() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }

        if (mockEnabled) {
            log.warn("Firebase Authentication is running in MOCK mode. Live token verification will be simulated.");
            return;
        }

        try {
            InputStream serviceAccount;
            if (firebaseConfigPath != null && !firebaseConfigPath.trim().isEmpty()) {
                log.info("Loading Firebase credentials from file: {}", firebaseConfigPath);
                serviceAccount = new FileInputStream(firebaseConfigPath);
            } else {
                log.info("Attempting to load Google Application Default Credentials (ADC)...");
                serviceAccount = GoogleCredentials.getApplicationDefault().getAccessToken() != null
                        ? null : null; // Fallback to ADC
            }

            FirebaseOptions options;
            if (serviceAccount != null) {
                options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();
            } else {
                options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.getApplicationDefault())
                        .build();
            }

            FirebaseApp.initializeApp(options);
            log.info("Firebase App initialized successfully.");
        } catch (Exception e) {
            log.warn("Firebase Admin SDK failed to initialize with live credentials: {}. Falling back to mock authentication mode.", e.getMessage());
        }
    }
}
