package com.latyr.api;

import com.latyr.api.exception.AnalysisOutcomeUnknownException;
import com.latyr.api.mapper.IngestionJobMapper;
import com.latyr.api.mapper.IngestionStageMapper;
import com.latyr.api.service.DurableIngestionStore;
import com.latyr.api.support.PostgresTestDatabase;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@EnabledIfEnvironmentVariable(named="TEST_DATABASE_URL", matches=".+")
class DurableIngestionMigrationPostgresTest {
    @Test
    void upgradePreservesHistoryQuarantinesOrphansAndBlocksLegacyAmbiguousAnalysisAcrossUsers() throws Exception {
        try (var db = new PostgresTestDatabase("7")) {
            UUID user = UUID.randomUUID();
            UUID source = UUID.randomUUID();
            UUID legacyCapture = UUID.randomUUID();
            UUID legacyJob = UUID.randomUUID();
            UUID orphanCapture = UUID.randomUUID();
            UUID orphanJob = UUID.randomUUID();
            UUID firstEntity = UUID.fromString("00000000-0000-0000-0000-000000000001");
            UUID secondEntity = UUID.fromString("00000000-0000-0000-0000-000000000002");
            db.jdbc().update("INSERT INTO users(id,firebase_uid,email) VALUES(?,?,?)",user,user.toString(),"test@example.invalid");
            db.jdbc().update("INSERT INTO canonical_sources(id,canonical_url_hash,source_type,original_url) VALUES(?,?,'IMAGE','private-image')",source,source.toString());
            db.jdbc().update("INSERT INTO captures(id,user_id,canonical_source_id,content_type,status,title) VALUES(?,?,?,'IMAGE','PROCESSING','Preserve title')",legacyCapture,user,source);
            db.jdbc().update("INSERT INTO ingestion_jobs(id,capture_id,user_id,source_type,payload,status,attempt_count) VALUES(?,?,?,'IMAGE','{\"caption\":\"preserve payload\"}','PROCESSING',1)",legacyJob,legacyCapture,user);
            for (UUID entity : new UUID[]{secondEntity,firstEntity}) {
                db.jdbc().update("INSERT INTO extracted_entities(id,capture_id,entity_type,title,action_cta,created_at) VALUES(?,?,'IDEA',?,'REMEMBER',TIMESTAMPTZ '2026-10-01T00:00:00Z')",entity,legacyCapture,entity.toString());
            }
            db.jdbc().update("INSERT INTO captures(id,user_id,content_type,title) VALUES(?,?,'IMAGE','Orphan title')",orphanCapture,user);
            db.jdbc().update("INSERT INTO ingestion_jobs(id,capture_id,user_id,source_type,payload) VALUES(?,?,?,'IMAGE','{\"caption\":\"orphan payload\"}')",orphanJob,orphanCapture,user);
            db.migrate(null);
            assertEquals(2,db.jdbc().queryForObject("SELECT count(*) FROM captures",Integer.class));
            assertEquals(2,db.jdbc().queryForObject("SELECT count(*) FROM ingestion_jobs",Integer.class));
            assertEquals("Preserve title",db.jdbc().queryForObject("SELECT title FROM captures WHERE id=?",String.class,legacyCapture));
            assertEquals("preserve payload",db.jdbc().queryForObject("SELECT payload->>'caption' FROM ingestion_jobs WHERE id=?",String.class,legacyJob));
            assertEquals("PROCESSING",db.jdbc().queryForObject("SELECT status FROM ingestion_jobs WHERE id=?",String.class,legacyJob));
            assertEquals(1,db.jdbc().queryForObject("SELECT attempt_count FROM ingestion_jobs WHERE id=?",Integer.class,legacyJob));
            assertEquals("FAILED",db.jdbc().queryForObject("SELECT status FROM ingestion_jobs WHERE id=?",String.class,orphanJob));
            assertEquals("SOURCE_MISSING",db.jdbc().queryForObject("SELECT error_detail FROM ingestion_jobs WHERE id=?",String.class,orphanJob));
            assertEquals("FAILED",db.jdbc().queryForObject("SELECT status FROM captures WHERE id=?",String.class,orphanCapture));
            assertEquals("orphan payload",db.jdbc().queryForObject("SELECT payload->>'caption' FROM ingestion_jobs WHERE id=?",String.class,orphanJob));
            assertEquals("AMBIGUOUS",db.jdbc().queryForObject("SELECT status FROM ingestion_stage_checkpoints WHERE canonical_source_id=?",String.class,source));
            assertEquals(2,db.jdbc().queryForObject("SELECT count(*) FROM extracted_entities",Integer.class));
            assertEquals(0,db.jdbc().queryForObject("SELECT extraction_index FROM extracted_entities WHERE id=?",Integer.class,firstEntity));
            assertEquals(1,db.jdbc().queryForObject("SELECT extraction_index FROM extracted_entities WHERE id=?",Integer.class,secondEntity));
            var store = new DurableIngestionStore(db.mapper(IngestionJobMapper.class),db.mapper(IngestionStageMapper.class),db.manager());
            var recovered = store.claim("recovery",60).orElseThrow();
            assertTrue(recovered.isRecoveryAmbiguous());
            assertThrows(AnalysisOutcomeUnknownException.class, () -> store.startStage(recovered,"ANALYSIS"));
            store.retryOrFail(recovered,false,"AMBIGUOUS_ANALYSIS");
            UUID otherUser = UUID.randomUUID();
            UUID otherCapture = UUID.randomUUID();
            db.jdbc().update("INSERT INTO users(id,firebase_uid,email) VALUES(?,?,?)",otherUser,otherUser.toString(),"other@example.invalid");
            db.jdbc().update("INSERT INTO captures(id,user_id,canonical_source_id,content_type) VALUES(?,?,?,'IMAGE')",otherCapture,otherUser,source);
            db.jdbc().update("INSERT INTO ingestion_jobs(capture_id,user_id,canonical_source_id,source_type,payload) VALUES(?,?,?,'IMAGE','{}')",otherCapture,otherUser,source);
            var nextUserJob = store.claim("new-user",60).orElseThrow();
            assertFalse(nextUserJob.isRecoveryAmbiguous());
            assertThrows(AnalysisOutcomeUnknownException.class, () -> store.startStage(nextUserJob,"ANALYSIS"));
        }
    }
}
