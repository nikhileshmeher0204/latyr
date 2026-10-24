package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.JsonbTypeHandler;
import com.latyr.api.domain.enums.JobStatus;
import com.latyr.api.domain.model.IngestionJob;
import org.apache.ibatis.annotations.*;
import org.apache.ibatis.type.JdbcType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface IngestionJobMapper {

    @Select("SELECT * FROM ingestion_jobs WHERE id = #{id}")
    @Results(id = "IngestionJobResult", value = {
        @Result(property = "id", column = "id"),
        @Result(property = "captureId", column = "capture_id"),
        @Result(property = "canonicalSourceId", column = "canonical_source_id"),
        @Result(property = "leaseToken", column = "lease_token"),
        @Result(property = "leaseExpiresAt", column = "lease_expires_at"),
        @Result(property = "nextAttemptAt", column = "next_attempt_at"),
        @Result(property = "recoveryAmbiguous", column = "recovery_ambiguous"),
        @Result(property = "userId", column = "user_id"),
        @Result(property = "sourceType", column = "source_type"),
        @Result(property = "payload", column = "payload", typeHandler = JsonbTypeHandler.class),
        @Result(property = "status", column = "status"),
        @Result(property = "attemptCount", column = "attempt_count"),
        @Result(property = "maxAttempts", column = "max_attempts"),
        @Result(property = "lockedAt", column = "locked_at"),
        @Result(property = "lockedBy", column = "locked_by"),
        @Result(property = "createdAt", column = "created_at"),
        @Result(property = "updatedAt", column = "updated_at")
    })
    Optional<IngestionJob> findById(@Param("id") UUID id);

    @Select("SELECT * FROM ingestion_jobs WHERE capture_id = #{captureId}")
    @ResultMap("IngestionJobResult")
    Optional<IngestionJob> findByCaptureId(@Param("captureId") UUID captureId);

    @Select("SELECT * FROM ingestion_jobs WHERE status = #{status} ORDER BY created_at ASC LIMIT #{limit}")
    @ResultMap("IngestionJobResult")
    List<IngestionJob> findByStatus(@Param("status") JobStatus status, @Param("limit") int limit);

    @Select("SELECT COUNT(1) > 0 FROM ingestion_jobs WHERE user_id = #{userId} AND status IN ('PENDING', 'PROCESSING') AND payload->>'url' = #{url}")
    boolean hasActiveJobForUrl(@Param("userId") UUID userId, @Param("url") String url);

    @Select("SELECT * FROM ingestion_jobs WHERE user_id = #{userId} AND status IN ('PENDING', 'PROCESSING') AND payload->>'url' = #{url} ORDER BY created_at DESC LIMIT 1")
    @ResultMap("IngestionJobResult")
    Optional<IngestionJob> findActiveJobForUrl(@Param("userId") UUID userId, @Param("url") String url);


    @Insert("""
        INSERT INTO ingestion_jobs (id, capture_id, canonical_source_id, user_id, source_type, payload, status, attempt_count, max_attempts, locked_at, locked_by, created_at, updated_at)
        VALUES (
            COALESCE(#{id}, gen_random_uuid()),
            #{captureId},
            COALESCE(#{canonicalSourceId}, (SELECT canonical_source_id FROM captures WHERE id = #{captureId})),
            #{userId},
            #{sourceType},
            #{payload, typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler, jdbcType=OTHER},
            #{status},
            #{attemptCount},
            #{maxAttempts},
            #{lockedAt},
            #{lockedBy},
            COALESCE(#{createdAt}, CURRENT_TIMESTAMP),
            CURRENT_TIMESTAMP
        )
    """)
    int insert(IngestionJob job);

    @Update("""
        UPDATE ingestion_jobs
        SET status = #{status},
            attempt_count = #{attemptCount},
            locked_at = #{lockedAt},
            locked_by = #{lockedBy},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id} AND lease_token = #{leaseToken} AND lease_expires_at > clock_timestamp()
    """)
    int update(IngestionJob job);


    @Delete("DELETE FROM ingestion_jobs WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);

    @Select("""
        SELECT j.* FROM ingestion_jobs j
        WHERE j.canonical_source_id IS NOT NULL
          AND ((j.status = 'PENDING' AND j.next_attempt_at <= clock_timestamp())
            OR (j.status = 'PROCESSING' AND j.lease_expires_at <= clock_timestamp()))
          AND NOT EXISTS (SELECT 1 FROM canonical_source_leases l
            WHERE l.canonical_source_id = j.canonical_source_id AND l.job_id IS NOT NULL AND l.lease_expires_at > clock_timestamp())
        ORDER BY j.next_attempt_at, j.created_at, j.id LIMIT 16 FOR UPDATE OF j SKIP LOCKED
        """)
    @ResultMap("IngestionJobResult")
    List<IngestionJob> findClaimCandidates();

    @Insert("INSERT INTO canonical_source_leases(canonical_source_id) VALUES(#{sourceId}) ON CONFLICT DO NOTHING")
    int ensureSourceLease(@Param("sourceId") UUID sourceId);

    @Update("""
        UPDATE canonical_source_leases SET job_id = #{job.id}, lease_token = #{token},
          lease_expires_at = clock_timestamp() + make_interval(secs => #{seconds})
        WHERE canonical_source_id = #{job.canonicalSourceId}
          AND (job_id IS NULL OR lease_expires_at IS NULL OR lease_expires_at <= clock_timestamp())
        """)
    int acquireSourceLease(@Param("job") IngestionJob job, @Param("token") UUID token, @Param("seconds") int seconds);

    @Update("""
        UPDATE ingestion_jobs SET status = 'PROCESSING', attempt_count = attempt_count + 1,
          locked_by = #{worker}, locked_at = clock_timestamp(), lease_token = #{token},
          lease_expires_at = clock_timestamp() + make_interval(secs => #{seconds}), updated_at = clock_timestamp()
        WHERE id = #{id}
        """)
    int claimLockedJob(@Param("id") UUID id, @Param("worker") String worker, @Param("token") UUID token, @Param("seconds") int seconds);

    @Select("""
        SELECT * FROM ingestion_jobs WHERE id = #{id} AND lease_token = #{leaseToken}
          AND status = 'PROCESSING' AND lease_expires_at > clock_timestamp() FOR UPDATE
        """)
    @ResultMap("IngestionJobResult")
    Optional<IngestionJob> lockCurrentLease(IngestionJob job);

    @Select("""
        SELECT canonical_source_id FROM canonical_source_leases WHERE canonical_source_id = #{canonicalSourceId}
          AND job_id = #{id} AND lease_token = #{leaseToken} AND lease_expires_at > clock_timestamp() FOR UPDATE
        """)
    Optional<UUID> lockCurrentSourceLease(IngestionJob job);

    @Update("""
        UPDATE ingestion_jobs SET lease_expires_at = clock_timestamp() + make_interval(secs => #{seconds})
        WHERE id = #{job.id} AND lease_token = #{job.leaseToken} AND status = 'PROCESSING'
          AND lease_expires_at > clock_timestamp()
        """)
    int renewJob(@Param("job") IngestionJob job, @Param("seconds") int seconds);

    @Update("""
        UPDATE canonical_source_leases SET lease_expires_at = clock_timestamp() + make_interval(secs => #{seconds})
        WHERE canonical_source_id = #{job.canonicalSourceId} AND job_id = #{job.id} AND lease_token = #{job.leaseToken}
        """)
    int renewSource(@Param("job") IngestionJob job, @Param("seconds") int seconds);

    @Update("""
        UPDATE ingestion_jobs SET status = #{status}, error_detail = #{errorCode},
          next_attempt_at = clock_timestamp() + make_interval(secs => #{delay}), locked_at = NULL,
          locked_by = NULL, lease_expires_at = NULL, lease_token = NULL,
          attempt_count = attempt_count - #{undoAttempt}, updated_at = clock_timestamp()
        WHERE id = #{job.id} AND lease_token = #{job.leaseToken} AND status = 'PROCESSING'
        """)
    int finishLease(@Param("job") IngestionJob job, @Param("status") String status,
        @Param("errorCode") String errorCode, @Param("delay") int delay, @Param("undoAttempt") int undoAttempt);

    @Update("""
        UPDATE canonical_source_leases SET job_id = NULL, lease_token = NULL, lease_expires_at = NULL
        WHERE canonical_source_id = #{canonicalSourceId} AND job_id = #{id} AND lease_token = #{leaseToken}
        """)
    int releaseSourceLease(IngestionJob job);
}
