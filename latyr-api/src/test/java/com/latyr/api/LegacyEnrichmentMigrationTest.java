package com.latyr.api;

import com.latyr.api.support.PostgresTestDatabase;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@EnabledIfEnvironmentVariable(named = "TEST_DATABASE_URL", matches = ".+")
class LegacyEnrichmentMigrationTest {
    @Test
    void pendingLegacyEnrichmentMovesToLeasedJobsWithoutChangingCapturesOrUsage() throws Exception {
        try (var db = new PostgresTestDatabase("9")) {
            UUID user = UUID.randomUUID();
            UUID source = UUID.randomUUID();
            db.jdbc().update("INSERT INTO users(id,firebase_uid,email) VALUES(?,?,?)", user, user.toString(), "test@example.test");
            db.jdbc().update("INSERT INTO user_subscriptions(user_id, monthly_capture_count) VALUES(?,3)", user);
            db.jdbc().update("INSERT INTO canonical_sources(id,canonical_url_hash,source_type,original_url) VALUES(?,?,?,?)",
                    source, source.toString(), "INSTAGRAM_REEL", "https://example.test/fixture");
            UUID terminalCapture = capture(db, user, source, true);
            UUID missingJobCapture = capture(db, user, source, true);
            UUID activeCapture = capture(db, user, source, true);
            UUID finishedCapture = capture(db, user, source, false);
            UUID completedJob = job(db, terminalCapture, user, "COMPLETED", 2);
            UUID activeJob = job(db, activeCapture, user, "PENDING", 1);
            UUID untouchedJob = job(db, finishedCapture, user, "COMPLETED", 1);
            var capturesBefore = db.jdbc().queryForList("SELECT row_to_json(c)::text FROM captures c ORDER BY id", String.class);
            var entitiesBefore = db.jdbc().queryForList("SELECT row_to_json(e)::text FROM extracted_entities e ORDER BY id", String.class);

            db.migrate(null);

            assertEquals(capturesBefore, db.jdbc().queryForList("SELECT row_to_json(c)::text FROM captures c ORDER BY id", String.class));
            assertEquals(entitiesBefore, db.jdbc().queryForList("SELECT row_to_json(e)::text FROM extracted_entities e ORDER BY id", String.class));
            assertEquals(3, db.jdbc().queryForObject("SELECT monthly_capture_count FROM user_subscriptions WHERE user_id=?", Integer.class, user));
            assertEquals("PENDING", db.jdbc().queryForObject("SELECT status FROM ingestion_jobs WHERE id=?", String.class, completedJob));
            assertEquals(0, db.jdbc().queryForObject("SELECT attempt_count FROM ingestion_jobs WHERE id=?", Integer.class, completedJob));
            assertEquals("2", db.jdbc().queryForObject("SELECT payload->>'legacy_attempt_count' FROM ingestion_jobs WHERE id=?", String.class, completedJob));
            assertEquals("true", db.jdbc().queryForObject("SELECT payload->>'enrichment_only' FROM ingestion_jobs WHERE id=?", String.class, completedJob));
            assertEquals("INSTAGRAM_REEL", db.jdbc().queryForObject("SELECT source_type FROM ingestion_jobs WHERE capture_id=?", String.class, missingJobCapture));
            assertEquals("true", db.jdbc().queryForObject("SELECT payload->>'enrichment_only' FROM ingestion_jobs WHERE capture_id=?", String.class, missingJobCapture));
            assertEquals(1, db.jdbc().queryForObject("SELECT attempt_count FROM ingestion_jobs WHERE id=?", Integer.class, activeJob));
            assertEquals(0, db.jdbc().queryForObject("SELECT count(*) FROM ingestion_jobs WHERE id=? AND payload->>'enrichment_only' IS NOT NULL", Integer.class, activeJob));
            assertEquals("COMPLETED", db.jdbc().queryForObject("SELECT status FROM ingestion_jobs WHERE id=?", String.class, untouchedJob));
            assertEquals(4, db.jdbc().queryForObject("SELECT count(*) FROM ingestion_jobs", Integer.class));
        }
    }

    private static UUID capture(PostgresTestDatabase db, UUID user, UUID source, boolean pending) {
        UUID capture = UUID.randomUUID();
        db.jdbc().update("INSERT INTO captures(id,user_id,canonical_source_id,content_type,status,title) VALUES(?,?,?,'URL','COMPLETED','Keep title')",
                capture, user, source);
        db.jdbc().update("INSERT INTO extracted_entities(capture_id,entity_type,title,action_cta,enrichment_status) VALUES(?,'MOVIE','Keep entity','WATCH',?)",
                capture, pending ? "PENDING" : "ENRICHED");
        return capture;
    }

    private static UUID job(PostgresTestDatabase db, UUID capture, UUID user, String status, int attempts) {
        UUID job = UUID.randomUUID();
        db.jdbc().update("INSERT INTO ingestion_jobs(id,capture_id,user_id,source_type,payload,status,attempt_count) VALUES(?,?,?,'INSTAGRAM_REEL','{}'::jsonb,?,?)",
                job, capture, user, status, attempts);
        return job;
    }
}
