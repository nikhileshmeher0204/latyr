package com.latyr.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.latyr.api.controller.RevenueCatWebhookController;
import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.domain.enums.SubscriptionEventType;
import com.latyr.api.domain.model.User;
import com.latyr.api.domain.model.UserSubscription;
import com.latyr.api.domain.model.UserSubscriptionHistory;
import com.latyr.api.mapper.UserMapper;
import com.latyr.api.mapper.UserSubscriptionHistoryMapper;
import com.latyr.api.mapper.UserSubscriptionMapper;
import com.latyr.api.service.SubscriptionQuotaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class RevenueCatWebhookControllerTest {

    private MockMvc mockMvc;
    private SubscriptionQuotaService subscriptionQuotaService;
    private UserSubscriptionMapper subscriptionMapper;
    private UserSubscriptionHistoryMapper historyMapper;
    private UserMapper userMapper;
    private ObjectMapper objectMapper;

    private final String SECRET = "test_rc_secret_123";

    @BeforeEach
    void setUp() {
        subscriptionMapper = mock(UserSubscriptionMapper.class);
        historyMapper = mock(UserSubscriptionHistoryMapper.class);
        userMapper = mock(UserMapper.class);
        objectMapper = new ObjectMapper();

        subscriptionQuotaService = new SubscriptionQuotaService(
                subscriptionMapper,
                historyMapper,
                userMapper
        );

        RevenueCatWebhookController controller = new RevenueCatWebhookController(subscriptionQuotaService);
        ReflectionTestUtils.setField(controller, "webhookSecret", SECRET);

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new com.latyr.api.exception.GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("Webhook Auth: Missing or invalid secret should return 401 Unauthorized")
    void testWebhook_Unauthorized() throws Exception {
        mockMvc.perform(post("/api/v1/webhooks/revenuecat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer invalid_secret")
                        .content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("INITIAL_PURCHASE: Should upgrade user subscription to PRO with 1000 quota")
    void testWebhook_InitialPurchase() throws Exception {
        UUID userId = UUID.randomUUID();
        String firebaseUid = "fb_user_123";

        User user = new User();
        user.setId(userId);
        user.setFirebaseUid(firebaseUid);

        UserSubscription sub = new UserSubscription();
        sub.setId(UUID.randomUUID());
        sub.setUserId(userId);
        sub.setPlanTier(PlanTier.FREE);
        sub.setQuotaLimit(30);

        when(userMapper.findByFirebaseUid(firebaseUid)).thenReturn(Optional.of(user));
        when(subscriptionMapper.findByUserId(userId)).thenReturn(Optional.of(sub));

        Map<String, Object> payload = Map.of(
                "api_version", "1.0",
                "event", Map.of(
                        "type", "INITIAL_PURCHASE",
                        "app_user_id", firebaseUid,
                        "product_id", "latyr_pro_monthly",
                        "expiration_at_ms", System.currentTimeMillis() + 30L * 24 * 3600 * 1000,
                        "price_in_purchased_currency", 4.99,
                        "currency", "USD",
                        "transaction_id", "rc_txn_001"
                )
        );

        mockMvc.perform(post("/api/v1/webhooks/revenuecat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + SECRET)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RECEIVED"));

        verify(subscriptionMapper, times(1)).update(argThat(s ->
                s.getPlanTier() == PlanTier.PRO && s.getQuotaLimit() == 1000
        ));
        verify(historyMapper, times(1)).insert(argThat(h ->
                h.getEventType() == SubscriptionEventType.UPGRADE && h.getAmountPaid().doubleValue() == 4.99
        ));
    }

    @Test
    @DisplayName("CANCELLATION: Should downgrade user subscription to FREE with 30 quota")
    void testWebhook_Cancellation() throws Exception {
        UUID userId = UUID.randomUUID();
        String firebaseUid = "fb_user_123";

        User user = new User();
        user.setId(userId);
        user.setFirebaseUid(firebaseUid);

        UserSubscription sub = new UserSubscription();
        sub.setId(UUID.randomUUID());
        sub.setUserId(userId);
        sub.setPlanTier(PlanTier.PRO);
        sub.setQuotaLimit(1000);

        when(userMapper.findByFirebaseUid(firebaseUid)).thenReturn(Optional.of(user));
        when(subscriptionMapper.findByUserId(userId)).thenReturn(Optional.of(sub));

        Map<String, Object> payload = Map.of(
                "api_version", "1.0",
                "event", Map.of(
                        "type", "CANCELLATION",
                        "app_user_id", firebaseUid,
                        "product_id", "latyr_pro_monthly",
                        "transaction_id", "rc_txn_002"
                )
        );

        mockMvc.perform(post("/api/v1/webhooks/revenuecat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + SECRET)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RECEIVED"));

        verify(subscriptionMapper, times(1)).update(argThat(s ->
                s.getPlanTier() == PlanTier.FREE && s.getQuotaLimit() == 30 && s.getExpiresAt() == null
        ));
        verify(historyMapper, times(1)).insert(argThat(h ->
                h.getEventType() == SubscriptionEventType.CANCELLATION
        ));
    }
}
