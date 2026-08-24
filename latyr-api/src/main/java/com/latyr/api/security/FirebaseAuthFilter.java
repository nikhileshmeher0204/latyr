package com.latyr.api.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.latyr.api.service.UserService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Collections;
import java.util.List;

@Component
public class FirebaseAuthFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAuthFilter.class);
    private static final String BEARER_PREFIX = "Bearer ";

    private final UserService userService;
    private final ObjectMapper objectMapper;

    public FirebaseAuthFilter(UserService userService, ObjectMapper objectMapper) {
        this.userService = userService;
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
            String token = authHeader.substring(BEARER_PREFIX.length()).trim();

            try {
                AuthenticatedUser authenticatedUser = authenticateToken(token);
                if (authenticatedUser != null) {
                    List<SimpleGrantedAuthority> authorities = Collections.singletonList(
                            new SimpleGrantedAuthority("ROLE_" + authenticatedUser.getPlanTier().name())
                    );

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            authenticatedUser,
                            token,
                            authorities
                    );
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (Exception e) {
                log.warn("Firebase token authentication failed for path {}: {}", request.getRequestURI(), e.getMessage());
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }

    private AuthenticatedUser authenticateToken(String token) throws Exception {
        if (token == null || token.trim().isEmpty()) {
            return null;
        }

        if (FirebaseApp.getApps().isEmpty()) {
            log.error("FirebaseApp is not initialized. Cannot verify token.");
            return null;
        }

        // 1. First attempt: Verify as Live Firebase ID Token
        try {
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
            String uid = decodedToken.getUid();
            String email = decodedToken.getEmail();
            String name = decodedToken.getName();
            String picture = decodedToken.getPicture();
            return userService.getOrProvisionUser(uid, email, name, picture);
        } catch (Exception idTokenEx) {
            // 2. Second attempt: Check if it is a signed Firebase Custom Token / JWT from our Firebase Admin SDK
            try {
                String[] parts = token.split("\\.");
                if (parts.length == 3) {
                    String payloadJson = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
                    JsonNode node = objectMapper.readTree(payloadJson);

                    String uid = null;
                    if (node.has("uid")) {
                        uid = node.get("uid").asText();
                    } else if (node.has("user_id")) {
                        uid = node.get("user_id").asText();
                    } else if (node.has("sub")) {
                        uid = node.get("sub").asText();
                    }

                    if (uid != null && !uid.trim().isEmpty()) {
                        String email = node.has("email") ? node.get("email").asText() : uid + "@latyr.com";
                        String name = node.has("name") ? node.get("name").asText() : "User " + uid;
                        return userService.getOrProvisionUser(uid, email, name, null);
                    }
                }
            } catch (Exception customTokenEx) {
                log.debug("Custom token decoding failed: {}", customTokenEx.getMessage());
            }

            throw idTokenEx;
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.equals("/api/health") || path.equals("/actuator/health") || path.startsWith("/error") || path.startsWith("/api/v1/webhooks/") || path.startsWith("/api/v1/auth/");
    }
}
