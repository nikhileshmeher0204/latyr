package com.latyr.api.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.latyr.api.client.FirebaseIdentityTokenVerifier;
import com.latyr.api.service.UserService;
import jakarta.servlet.Filter;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.MockedStatic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.mock.web.MockServletContext;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.support.AnnotationConfigWebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class FirebaseSecurityChainTest {

    private AnnotationConfigWebApplicationContext context;
    private MockedStatic<FirebaseApp> firebaseApps;
    private MockedStatic<FirebaseAuth> firebaseAuth;
    private FirebaseAuth provider;
    private UserService users;
    private MockMvc mvc;

    @BeforeEach
    void setUp() throws Exception {
        firebaseApps = mockStatic(FirebaseApp.class);
        firebaseApps.when(FirebaseApp::getApps).thenReturn(List.of(mock(FirebaseApp.class)));
        provider = mock(FirebaseAuth.class);
        when(provider.verifyIdToken(anyString())).thenThrow(new IllegalArgumentException("Rejected token"));
        firebaseAuth = mockStatic(FirebaseAuth.class);
        firebaseAuth.when(FirebaseAuth::getInstance).thenReturn(provider);

        context = new AnnotationConfigWebApplicationContext();
        context.setServletContext(new MockServletContext());
        context.register(TestConfiguration.class, SecurityConfig.class);
        context.refresh();
        users = context.getBean(UserService.class);
        when(users.getOrProvisionUser(any(), any(), any(), any())).thenReturn(
                new AuthenticatedUser(UUID.randomUUID(), "verified-user", "user@example.test"));
        mvc = MockMvcBuilders.webAppContextSetup(context)
                .addFilters(context.getBean("springSecurityFilterChain", Filter.class)).build();
    }

    @AfterEach
    void tearDown() {
        if (context != null) context.close();
        if (firebaseAuth != null) firebaseAuth.close();
        if (firebaseApps != null) firebaseApps.close();
    }

    @Test
    void missingTokenCannotReachProtectedEndpoint() throws Exception {
        mvc.perform(get("/api/v1/security-probe"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.error").value("UNAUTHORIZED"));
        verifyNoInteractions(users, provider);
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/v1/auth/token", "/api/v1/auth/reset-data",
            "/api/v1/ai/analyze-url", "/api/v1/ai/analyze-image",
            "/api/v1/ai/analyze-media", "/api/v1/ai/analyze-text"})
    void diagnosticNamespacesAreNotPublic(String path) throws Exception {
        mvc.perform(get(path)).andExpect(status().isUnauthorized());
        verifyNoInteractions(users, provider);
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/v1/auth/token", "/api/v1/auth/reset-data",
            "/api/v1/ai/analyze-url", "/api/v1/ai/analyze-image",
            "/api/v1/ai/analyze-media", "/api/v1/ai/analyze-text"})
    void removedDiagnosticsHaveNoAuthenticatedRoute(String path) throws Exception {
        stubVerifiedIdentity("google.com");
        mvc.perform(get(path).header("Authorization", "Bearer verified-id-token"))
                .andExpect(status().isNotFound());
        verify(users).getOrProvisionUser("verified-user", "user@example.test", null, null);
    }

    @Test
    void healthRemainsPublic() throws Exception {
        mvc.perform(get("/api/health")).andExpect(status().isOk());
        verifyNoInteractions(users, provider);
    }

    @ParameterizedTest
    @ValueSource(strings = {"dev-attacker", "mock-dev-token", "not-a-token", " ",
            "eyJhbGciOiJub25lIn0.eyJ1aWQiOiJhdHRhY2tlciJ9.Zm9yZ2Vk",
            "eyJhbGciOiJub25lIn0.eyJ1c2VyX2lkIjoiYXR0YWNrZXIifQ.Zm9yZ2Vk",
            "eyJhbGciOiJub25lIn0.eyJzdWIiOiJhdHRhY2tlciJ9.Zm9yZ2Vk"})
    void rejectedTokensCannotProvisionOrAuthenticate(String token) throws Exception {
        mvc.perform(get("/api/v1/security-probe").header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(users);
    }

    @Test
    void verifiedIdentityReachesProtectedEndpoint() throws Exception {
        stubVerifiedIdentity("google.com");

        mvc.perform(get("/api/v1/security-probe").header("Authorization", "Bearer verified-id-token"))
                .andExpect(status().isOk()).andExpect(content().string("verified-user"));
        verify(users).getOrProvisionUser("verified-user", "user@example.test", null, null);
        mvc.perform(get("/api/v1/security-probe")).andExpect(status().isUnauthorized());
    }

    @ParameterizedTest
    @ValueSource(strings = {"anonymous", "password", "custom", "facebook.com", ""})
    void verifiedButUnsupportedSignInProviderCannotProvision(String signInProvider) throws Exception {
        stubVerifiedIdentity(signInProvider);
        mvc.perform(get("/api/v1/security-probe").header("Authorization", "Bearer verified-id-token"))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(users);
    }

    @Test
    void verifiedAppleIdentityIsAccepted() throws Exception {
        stubVerifiedIdentity("apple.com");
        mvc.perform(get("/api/v1/security-probe").header("Authorization", "Bearer verified-id-token"))
                .andExpect(status().isOk());
        verify(users).getOrProvisionUser("verified-user", "user@example.test", null, null);
    }

    private void stubVerifiedIdentity(String signInProvider) throws Exception {
        FirebaseToken verified = mock(FirebaseToken.class);
        when(verified.getClaims()).thenReturn(Map.of("firebase", Map.of("sign_in_provider", signInProvider)));
        when(verified.getUid()).thenReturn("verified-user");
        when(verified.getEmail()).thenReturn("user@example.test");
        doReturn(verified).when(provider).verifyIdToken("verified-id-token");
    }

    @Test
    void missingFirebaseConfigurationFailsClosed() throws Exception {
        firebaseApps.when(FirebaseApp::getApps).thenReturn(List.of());
        mvc.perform(get("/api/v1/security-probe").header("Authorization", "Bearer unverified"))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(users, provider);
    }

    @Configuration
    @EnableWebMvc
    static class TestConfiguration {
        @Bean ObjectMapper objectMapper() { return new ObjectMapper().findAndRegisterModules(); }
        @Bean UserService userService() { return mock(UserService.class); }
        @Bean FirebaseAuthFilter firebaseAuthFilter(UserService users) {
            return new FirebaseAuthFilter(users, new FirebaseIdentityTokenVerifier());
        }
        @Bean ProbeController probeController() { return new ProbeController(); }
    }

    @RestController
    static class ProbeController {
        @GetMapping("/api/health")
        String health() { return "ok"; }

        @GetMapping("/api/v1/security-probe")
        String currentUser(@AuthenticationPrincipal AuthenticatedUser user) {
            return user.getFirebaseUid();
        }
    }
}
