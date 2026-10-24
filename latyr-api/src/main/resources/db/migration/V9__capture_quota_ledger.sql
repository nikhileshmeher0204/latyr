-- Keep historical counters intact; old admissions were charged before processing.
CREATE TABLE capture_quota_ledger (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    canonical_source_id UUID NOT NULL REFERENCES canonical_sources(id) ON DELETE CASCADE,
    capture_id UUID UNIQUE REFERENCES captures(id) ON DELETE SET NULL,
    state VARCHAR(16) NOT NULL CHECK (state IN ('RESERVED', 'FINALIZED', 'RELEASED')),
    grandfathered BOOLEAN NOT NULL DEFAULT FALSE,
    quota_cycle_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, canonical_source_id)
);

INSERT INTO capture_quota_ledger (user_id, canonical_source_id, capture_id, state, grandfathered)
SELECT DISTINCT ON (user_id, canonical_source_id)
       user_id, canonical_source_id, id,
       CASE WHEN status = 'COMPLETED' THEN 'FINALIZED'
            WHEN status IN ('PENDING', 'PROCESSING') THEN 'RESERVED'
            ELSE 'RELEASED' END,
       TRUE
FROM captures
WHERE canonical_source_id IS NOT NULL
ORDER BY user_id, canonical_source_id, (status = 'COMPLETED') DESC, created_at, id;

CREATE INDEX idx_capture_quota_reserved ON capture_quota_ledger(user_id)
    WHERE state = 'RESERVED' AND NOT grandfathered;
