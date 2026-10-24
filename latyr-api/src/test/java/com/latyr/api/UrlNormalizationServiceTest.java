package com.latyr.api;

import com.latyr.api.exception.LatyrException;

import com.latyr.api.service.UrlNormalizationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.*;

class UrlNormalizationServiceTest {

    private UrlNormalizationService normalizationService;

    @BeforeEach
    void setUp() {
        normalizationService = new UrlNormalizationService();
    }

    @Test
    @DisplayName("Should strip tracking query parameters (igsh, utm_source, etc.) and trailing slashes")
    void testNormalizeUrl_StripTrackingParameters() {
        String rawUrl1 = "https://www.instagram.com/reel/C8xyz123/?igsh=MXRkZ3J4eWJk&utm_source=ig_web_copy_link";
        String rawUrl2 = "https://instagram.com/reel/C8xyz123/";
        String rawUrl3 = "https://instagram.com/reel/C8xyz123";

        String normalized1 = normalizationService.normalizeUrl(rawUrl1);
        String normalized2 = normalizationService.normalizeUrl(rawUrl2);
        String normalized3 = normalizationService.normalizeUrl(rawUrl3);

        assertEquals("https://instagram.com/reel/C8xyz123", normalized1);
        assertEquals("https://instagram.com/reel/C8xyz123", normalized2);
        assertEquals("https://instagram.com/reel/C8xyz123", normalized3);
    }

    @Test
    @DisplayName("Identical canonical URLs must generate the exact same SHA-256 hash")
    void testGetCanonicalUrlHash_Determinism() {
        String urlWithTracking = "https://www.instagram.com/reel/C9ABC456/?utm_campaign=share&igsh=abc12345";
        String cleanUrl = "https://instagram.com/reel/C9ABC456";

        String hash1 = normalizationService.getCanonicalUrlHash(urlWithTracking);
        String hash2 = normalizationService.getCanonicalUrlHash(cleanUrl);

        assertNotNull(hash1);
        assertEquals(64, hash1.length()); // SHA-256 is 64 hex characters
        assertEquals(hash1, hash2);
    }

    @Test
    @DisplayName("Should compute accurate SHA-256 checksum for byte array image payloads")
    void testComputeSha256_Bytes() {
        byte[] imageBytes = "sample-screenshot-raw-bytes-png".getBytes(StandardCharsets.UTF_8);
        String hash = normalizationService.computeSha256(imageBytes);

        assertNotNull(hash);
        assertEquals(64, hash.length());

        // Idempotency check
        assertEquals(hash, normalizationService.computeSha256(imageBytes));
    }

    @Test
    @DisplayName("F16 Outbound policy: rejects private/loopback IPs and non-http schemes, allows valid public URLs")
    void testValidateOutboundUrl_RestrictedAndAllowedDestinations() {
        // Allowed public URLs
        assertDoesNotThrow(() -> normalizationService.validateOutboundUrl("https://www.instagram.com/reel/C8xyz123/"));
        assertDoesNotThrow(() -> normalizationService.validateOutboundUrl("https://github.com/torvalds/linux"));

        // Restricted localhost and loopback
        LatyrException ex1 = assertThrows(LatyrException.class, () ->
                normalizationService.validateOutboundUrl("http://localhost:8080/admin"));
        assertEquals("RESTRICTED_DESTINATION", ex1.getErrorCode());

        LatyrException ex2 = assertThrows(LatyrException.class, () ->
                normalizationService.validateOutboundUrl("http://127.0.0.1:9090"));
        assertEquals("RESTRICTED_DESTINATION", ex2.getErrorCode());

        // Restricted link-local / cloud metadata IP
        LatyrException ex3 = assertThrows(LatyrException.class, () ->
                normalizationService.validateOutboundUrl("http://169.254.169.254/latest/meta-data"));
        assertEquals("RESTRICTED_DESTINATION", ex3.getErrorCode());

        // Restricted scheme
        LatyrException ex4 = assertThrows(LatyrException.class, () ->
                normalizationService.validateOutboundUrl("file:///etc/passwd"));
        assertEquals("INVALID_URL_SCHEME", ex4.getErrorCode());
    }
}