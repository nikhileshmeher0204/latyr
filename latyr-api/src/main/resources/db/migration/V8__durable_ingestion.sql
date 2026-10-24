-- Keep existing rows and payloads; only add ownership, checkpoints and delivery state.
ALTER TABLE ingestion_jobs ADD COLUMN canonical_source_id UUID REFERENCES canonical_sources(id);
UPDATE ingestion_jobs j SET canonical_source_id = c.canonical_source_id FROM captures c WHERE c.id = j.capture_id;
ALTER TABLE ingestion_jobs ADD COLUMN lease_token UUID;
ALTER TABLE ingestion_jobs ADD COLUMN lease_expires_at TIMESTAMPTZ;
ALTER TABLE ingestion_jobs ADD COLUMN next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
-- Old PROCESSING rows have no durable checkpoint and may have called a paid provider.
-- Recovery must report ambiguity instead of blindly replaying that call.
ALTER TABLE ingestion_jobs ADD COLUMN recovery_ambiguous BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE ingestion_jobs SET recovery_ambiguous = TRUE, lease_expires_at = CURRENT_TIMESTAMP
 WHERE status = 'PROCESSING';
UPDATE ingestion_jobs SET status = 'FAILED', error_detail = 'SOURCE_MISSING', locked_at = NULL,
 locked_by = NULL, lease_expires_at = NULL
 WHERE canonical_source_id IS NULL AND status IN ('PENDING','PROCESSING');
UPDATE captures c SET status = 'FAILED', error_message = 'SOURCE_MISSING'
 WHERE c.status IN ('PENDING','PROCESSING') AND EXISTS (
   SELECT 1 FROM ingestion_jobs j WHERE j.capture_id = c.id AND j.error_detail = 'SOURCE_MISSING');
CREATE INDEX idx_ingestion_jobs_due ON ingestion_jobs(next_attempt_at, created_at) WHERE status IN ('PENDING','PROCESSING');

ALTER TABLE captures DROP CONSTRAINT captures_status_check;
ALTER TABLE captures ADD CONSTRAINT captures_status_check CHECK(status IN ('PENDING','PROCESSING','PARTIAL','COMPLETED','FAILED'));

ALTER TABLE extracted_entities ADD COLUMN extraction_index INT NOT NULL DEFAULT 0;
WITH ordered AS (
 SELECT id,(row_number() OVER (PARTITION BY capture_id ORDER BY created_at,id)-1)::INT AS ordinal
 FROM extracted_entities
)
UPDATE extracted_entities e SET extraction_index=o.ordinal FROM ordered o WHERE o.id=e.id;
CREATE INDEX idx_entities_capture_order ON extracted_entities(capture_id,extraction_index,id);

CREATE TABLE canonical_source_leases (
    canonical_source_id UUID PRIMARY KEY REFERENCES canonical_sources(id) ON DELETE CASCADE,
    job_id UUID REFERENCES ingestion_jobs(id) ON DELETE SET NULL,
    lease_token UUID,
    lease_expires_at TIMESTAMPTZ
);

CREATE TABLE ingestion_stage_checkpoints (
    canonical_source_id UUID NOT NULL REFERENCES canonical_sources(id) ON DELETE CASCADE,
    stage VARCHAR(32) NOT NULL CHECK(stage IN ('SOURCE','MEDIA','ANALYSIS','ENRICHMENT')),
    status VARCHAR(32) NOT NULL CHECK(status IN ('RUNNING','COMPLETED','FAILED','AMBIGUOUS')),
    job_id UUID REFERENCES ingestion_jobs(id) ON DELETE SET NULL,
    lease_token UUID NOT NULL,
    output JSONB,
    error_code VARCHAR(128),
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    PRIMARY KEY(canonical_source_id,stage)
);

CREATE TABLE ingestion_stage_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    canonical_source_id UUID NOT NULL REFERENCES canonical_sources(id) ON DELETE CASCADE,
    job_id UUID REFERENCES ingestion_jobs(id) ON DELETE SET NULL,
    lease_token UUID NOT NULL,
    stage VARCHAR(32) NOT NULL CHECK(stage IN ('SOURCE','MEDIA','ANALYSIS','ENRICHMENT')),
    status VARCHAR(32) NOT NULL CHECK(status IN ('RUNNING','COMPLETED','FAILED','EXPIRED','AMBIGUOUS')),
    error_code VARCHAR(128),
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    UNIQUE(job_id,lease_token,stage)
);
CREATE INDEX idx_ingestion_attempts_source ON ingestion_stage_attempts(canonical_source_id,started_at);

-- A different user's later job must not replay an uncheckpointed legacy call either.
INSERT INTO ingestion_stage_checkpoints(canonical_source_id,stage,status,job_id,lease_token,error_code,completed_at)
 SELECT DISTINCT ON (canonical_source_id) canonical_source_id,'ANALYSIS','AMBIGUOUS',id,
 gen_random_uuid(),'LEGACY_INFLIGHT_OUTCOME_UNKNOWN',CURRENT_TIMESTAMP
 FROM ingestion_jobs WHERE recovery_ambiguous AND canonical_source_id IS NOT NULL AND status = 'PROCESSING'
 ORDER BY canonical_source_id,created_at,id;

CREATE TABLE ingestion_event_outbox (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type VARCHAR(64) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','DELIVERING','DELIVERED','FAILED')),
    lease_token UUID,
    lease_expires_at TIMESTAMPTZ,
    attempt_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMPTZ
);
CREATE INDEX idx_ingestion_outbox_due ON ingestion_event_outbox(next_attempt_at,created_at) WHERE status IN ('PENDING','DELIVERING');
