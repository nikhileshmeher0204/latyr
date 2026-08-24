package com.latyr.api.security;

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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

@Component
public class FirebaseAuthFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAuthFilter.class);
    private static final String BEARER_PREFIX = "Bearer ";

    private final UserService userService;

    @Value("${firebase.auth.mock-enabled:false}")
    private boolean mockEnabled;

    public FirebaseAuthFilter(UserService userService) {
        this.userService = userService;
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
        if (token.isEmpty()) {
            return null;
        }

        // Mock token handling for local development / testing
        if (mockEnabled || token.startsWith("mock-") || token.equals("test-token")) {
            String uid = token.startsWith("mock-") ? token.substring(5) : "mock_firebase_uid_12345";
            String email = uid.contains("@") ? uid : uid + "@latyr.local";
            String displayName = "Mock User (" + uid + ")";
            return userService.getOrProvisionUser(uid, email, displayName, null);
        }

        // Live Firebase Token Verification
        if (FirebaseApp.getApps().isEmpty()) {
            log.error("FirebaseApp is not initialized. Cannot verify live tokens.");
            return null;
        }

        FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
        String uid = decodedToken.getUid();
        String email = decodedToken.getEmail();
        String name = decodedToken.getName();
        String picture = decodedToken.getPicture();

        return userService.getOrProvisionUser(uid, email, name, picture);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.equals("/api/health") || path.equals("/actuator/health") || path.startsWith("/error");
    }
}
