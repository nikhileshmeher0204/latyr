package com.latyr.api.security;

import com.latyr.api.client.IdentityTokenVerifier;
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
import java.util.Collections;
import java.util.List;

@Component
public class FirebaseAuthFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAuthFilter.class);
    private static final String BEARER_PREFIX = "Bearer ";

    private final UserService userService;
    private final IdentityTokenVerifier tokenVerifier;

    public FirebaseAuthFilter(UserService userService, IdentityTokenVerifier tokenVerifier) {
        this.userService = userService;
        this.tokenVerifier = tokenVerifier;
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
                            null,
                            authorities
                    );
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (Exception e) {
                log.warn("Firebase token authentication failed for path {}", request.getRequestURI());
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }

    private AuthenticatedUser authenticateToken(String token) throws Exception {
        if (token == null || token.trim().isEmpty()) {
            return null;
        }

        IdentityTokenVerifier.VerifiedIdentity verified = tokenVerifier.verify(token);
        if (verified.provider() != IdentityTokenVerifier.IdentityProvider.GOOGLE
                && verified.provider() != IdentityTokenVerifier.IdentityProvider.APPLE) {
            return null;
        }
        return userService.getOrProvisionUser(verified.uid(), verified.email(),
                verified.displayName(), verified.photoUrl());
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.equals("/api/health") || path.equals("/actuator/health") || path.startsWith("/error") || path.startsWith("/api/v1/webhooks/");
    }
}
