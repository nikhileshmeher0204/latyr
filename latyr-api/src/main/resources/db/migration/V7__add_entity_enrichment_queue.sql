-- Migration V7: Add entity enrichment status and async retry queue fields

ALTER TABLE extracted_entities 
ADD COLUMN IF NOT EXISTS enrichment_status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
ADD COLUMN IF NOT EXISTS retry_count INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS next_retry_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS enrichment_error TEXT;

CREATE INDEX IF NOT EXISTS idx_entities_enrichment_queue 
ON extracted_entities (enrichment_status, next_retry_at) 
WHERE enrichment_status = 'PENDING';
