package com.latyr.api.service;

import com.google.firebase.messaging.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class FcmService {

    private static final Logger log = LoggerFactory.getLogger(FcmService.class);

    @Value("${firebase.auth.mock-enabled:false}")
    private boolean mockEnabled;

    public boolean sendSilentSyncNotification(String fcmToken, UUID captureId) {
        if (fcmToken == null || fcmToken.trim().isEmpty()) {
            log.debug("Skipping silent sync push: empty FCM token for capture {}", captureId);
            return false;
        }

        if (mockEnabled) {
            log.info("FCM MOCK: Sent silent sync notification for capture {} to token {}", captureId, fcmToken);
            return true;
        }

        try {
            Message message = Message.builder()
                    .setToken(fcmToken)
                    .putData("type", "SILENT_SYNC")
                    .putData("capture_id", captureId.toString())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder().setContentAvailable(true).build())
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Successfully dispatched silent FCM sync for capture {}: messageId={}", captureId, response);
            return true;
        } catch (Exception e) {
            log.warn("Failed to dispatch silent FCM sync for capture {}: {}", captureId, e.getMessage());
            return false;
        }
    }

    public boolean sendRichResurfacingNotification(String fcmToken, String title, String body, UUID captureId, Map<String, String> extraData) {
        if (fcmToken == null || fcmToken.trim().isEmpty()) {
            log.debug("Skipping resurfacing push: empty FCM token for capture {}", captureId);
            return false;
        }

        if (mockEnabled) {
            log.info("FCM MOCK: Sent resurfacing push [{}] '{}' for capture {} to token {}", title, body, captureId, fcmToken);
            return true;
        }

        try {
            Map<String, String> data = new HashMap<>(extraData != null ? extraData : Map.of());
            data.put("type", "RESURFACING");
            if (captureId != null) {
                data.put("capture_id", captureId.toString());
            }

            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data)
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder().setSound("default").build())
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Successfully dispatched rich resurfacing push for capture {}: messageId={}", captureId, response);
            return true;
        } catch (Exception e) {
            log.warn("Failed to dispatch rich resurfacing push for capture {}: {}", captureId, e.getMessage());
            return false;
        }
    }
}
