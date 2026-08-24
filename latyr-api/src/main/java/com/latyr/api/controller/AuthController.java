package com.latyr.api.controller;

import com.google.firebase.auth.FirebaseAuth;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    @Autowired(required = false)
    private JdbcTemplate jdbcTemplate;

    @RequestMapping(value = "/token", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<Map<String, Object>> generateToken(
            @RequestParam(defaultValue = "nikhilesh_prod_user") String uid,
            @RequestParam(defaultValue = "nikhilesh@latyr.com") String email,
            @RequestParam(defaultValue = "Nikhilesh Meher") String name) throws Exception {

        log.info("Generating live Firebase Custom Token for UID: {}", uid);
        String customToken = FirebaseAuth.getInstance().createCustomToken(uid, Map.of(
                "email", email,
                "name", name
        ));

        return ResponseEntity.ok(Map.of(
                "token", customToken,
                "token_type", "Bearer",
                "uid", uid,
                "email", email,
                "name", name
        ));
    }

    @PostMapping("/reset-data")
    public ResponseEntity<Map<String, String>> resetData() {
        if (jdbcTemplate != null) {
            log.info("Wiping cache and captures for clean live test execution...");
            jdbcTemplate.execute("DELETE FROM extracted_entities");
            jdbcTemplate.execute("DELETE FROM ingestion_jobs");
            jdbcTemplate.execute("DELETE FROM captures");
            jdbcTemplate.execute("DELETE FROM canonical_sources");
        }
        return ResponseEntity.ok(Map.of("status", "CLEANED"));
    }
}
