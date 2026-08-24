package com.latyr.api.domain.repository;

import com.latyr.api.domain.entity.IngestionJob;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface IngestionJobRepository extends JpaRepository<IngestionJob, UUID> {

    @Query(value = """
        UPDATE ingestion_jobs
        SET status = 'PROCESSING',
            locked_at = CURRENT_TIMESTAMP,
            locked_by = :workerInstanceId
        WHERE id = (
            SELECT id
            FROM ingestion_jobs
            WHERE status = 'PENDING'
            ORDER BY created_at ASC
            LIMIT 1
            FOR UPDATE SKIP LOCKED
        )
        RETURNING *
        """, nativeQuery = true)
    Optional<IngestionJob> lockNextPendingJob(@Param("workerInstanceId") String workerInstanceId);
}
