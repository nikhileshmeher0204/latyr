package com.latyr.api.controller;

import com.latyr.api.exception.LatyrException;
import com.latyr.api.service.SubscriptionQuotaService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/webhooks/revenuecat")
public class RevenueCatWebhookController {

    private static final Logger log = LoggerFactory.getLogger(RevenueCatWebhookController.class);

    private final SubscriptionQuotaService subscriptionQuotaService;

    @Value("${revenuecat.webhook.secret:rc_webhook_secret_dev_123}")
    private String webhookSecret;

    public RevenueCatWebhookController(SubscriptionQuotaService subscriptionQuotaService) {
        this.subscriptionQuotaService = subscriptionQuotaService;
    }

    @PostMapping
    public ResponseEntity<Map<String, String>> handleWebhook(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody Map<String, Object> payload) {

        validateAuthorization(authHeader);

        log.info("Received valid RevenueCat billing webhook event");
        subscriptionQuotaService.handleRevenueCatEvent(payload);

        return ResponseEntity.ok(Map.of("status", "RECEIVED"));
    }

    private void validateAuthorization(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new LatyrException("Missing or invalid webhook authorization header", "UNAUTHORIZED_WEBHOOK", HttpStatus.UNAUTHORIZED);
        }

        String token = authHeader.substring(7).trim();
        if (!webhookSecret.trim().equals(token)) {
            throw new LatyrException("Invalid RevenueCat webhook secret", "UNAUTHORIZED_WEBHOOK", HttpStatus.UNAUTHORIZED);
        }
    }
}
