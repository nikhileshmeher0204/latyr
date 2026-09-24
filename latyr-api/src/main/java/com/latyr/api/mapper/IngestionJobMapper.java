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

    @Select("""
        UPDATE ingestion_jobs
        SET status = 'PROCESSING',
            locked_at = CURRENT_TIMESTAMP,
            locked_by = #{workerInstanceId},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = (
            SELECT id
            FROM ingestion_jobs
            WHERE status = 'PENDING'
            ORDER BY created_at ASC
            LIMIT 1
            FOR UPDATE SKIP LOCKED
        )
        RETURNING *
    """)
    @ResultMap("IngestionJobResult")
    Optional<IngestionJob> lockNextPendingJob(@Param("workerInstanceId") String workerInstanceId);

    @Insert("""
        INSERT INTO ingestion_jobs (id, capture_id, user_id, source_type, payload, status, attempt_count, max_attempts, locked_at, locked_by, created_at, updated_at)
        VALUES (
            COALESCE(#{id}, gen_random_uuid()),
            #{captureId},
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
        WHERE id = #{id}
    """)
    int update(IngestionJob job);

    @Update("""
        UPDATE ingestion_jobs
        SET status = 'PENDING',
            locked_at = NULL,
            locked_by = NULL,
            updated_at = CURRENT_TIMESTAMP
        WHERE status = 'PROCESSING'
          AND locked_at < (CURRENT_TIMESTAMP - (INTERVAL '1 minute' * #{thresholdMinutes}))
    """)
    int resetStaleLocks(@Param("thresholdMinutes") int thresholdMinutes);

    @Delete("DELETE FROM ingestion_jobs WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);
}
