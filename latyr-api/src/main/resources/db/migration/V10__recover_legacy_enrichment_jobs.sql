-- Move existing pending enrichment work onto the same leased job path.
-- Capture/entity data and legacy attempt history remain intact.
WITH recovery AS (
    SELECT DISTINCT ON (j.capture_id) j.id
    FROM ingestion_jobs j
    JOIN captures c ON c.id = j.capture_id
    WHERE c.status = 'COMPLETED'
      AND j.status IN ('COMPLETED', 'FAILED')
      AND EXISTS (SELECT 1 FROM extracted_entities e
                  WHERE e.capture_id = c.id AND e.enrichment_status = 'PENDING')
      AND NOT EXISTS (SELECT 1 FROM ingestion_jobs active
                      WHERE active.capture_id = c.id AND active.status IN ('PENDING', 'PROCESSING'))
    ORDER BY j.capture_id, j.updated_at DESC, j.id
)
UPDATE ingestion_jobs j
SET status = 'PENDING',
    payload = j.payload || jsonb_build_object('enrichment_only', true,
        'legacy_attempt_count', j.attempt_count, 'legacy_job_status', j.status),
    attempt_count = 0,
    locked_at = NULL,
    locked_by = NULL,
    lease_token = NULL,
    lease_expires_at = NULL,
    next_attempt_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE j.id IN (SELECT id FROM recovery);

INSERT INTO ingestion_jobs (id, capture_id, canonical_source_id, user_id, source_type,
                            payload, status, attempt_count, max_attempts, next_attempt_at)
SELECT gen_random_uuid(), c.id, c.canonical_source_id, c.user_id, COALESCE(c.source_type, s.source_type),
       '{"enrichment_only":true}'::jsonb, 'PENDING', 0, 3, CURRENT_TIMESTAMP
FROM captures c
JOIN canonical_sources s ON s.id = c.canonical_source_id
WHERE c.status = 'COMPLETED'
  AND c.canonical_source_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM extracted_entities e
              WHERE e.capture_id = c.id AND e.enrichment_status = 'PENDING')
  AND NOT EXISTS (SELECT 1 FROM ingestion_jobs j WHERE j.capture_id = c.id);
