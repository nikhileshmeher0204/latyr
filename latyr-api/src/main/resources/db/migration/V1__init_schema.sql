-- Enable pgcrypto extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Function to handle automated updated_at timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 1. USERS
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    photo_url TEXT,
    fcm_token TEXT,
    timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
    language VARCHAR(32) NOT NULL DEFAULT 'ENGLISH' CHECK (language IN ('ENGLISH', 'HINGLISH', 'HINDI', 'ORIGINAL')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_users_modtime BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. USER SUBSCRIPTIONS
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    plan_tier VARCHAR(32) NOT NULL DEFAULT 'FREE' CHECK (plan_tier IN ('FREE', 'PRO')),
    monthly_capture_count INT NOT NULL DEFAULT 0,
    quota_limit INT NOT NULL DEFAULT 30,
    quota_reset_at TIMESTAMPTZ NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 month'),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_user_subscriptions_modtime BEFORE UPDATE ON user_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. USER SUBSCRIPTION HISTORY
CREATE TABLE user_subscription_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_tier VARCHAR(32) NOT NULL,
    to_tier VARCHAR(32) NOT NULL,
    event_type VARCHAR(32) NOT NULL CHECK (event_type IN ('UPGRADE', 'DOWNGRADE', 'RENEWAL', 'CANCELLATION')),
    amount_paid NUMERIC(10,2) DEFAULT 0.00,
    currency VARCHAR(8) DEFAULT 'USD',
    provider_transaction_id VARCHAR(255),
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. COLLECTIONS (System Predefined Templates)
CREATE TABLE collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    category VARCHAR(64) NOT NULL,
    default_icon VARCHAR(64),
    feature_triggers JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_collections_modtime BEFORE UPDATE ON collections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. CANONICAL SOURCES (URL & Image Hash Deduplication Cache)
CREATE TABLE canonical_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    canonical_url_hash VARCHAR(64) NOT NULL UNIQUE,
    source_type VARCHAR(32) NOT NULL CHECK (source_type IN ('INSTAGRAM_REEL', 'YOUTUBE_SHORT', 'WEB_URL', 'IMAGE')),
    original_url TEXT NOT NULL,
    raw_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    ai_analysis_cache JSONB,
    scraping_duration_ms INT,
    ai_inference_duration_ms INT,
    total_processing_duration_ms INT,
    first_processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_canonical_sources_modtime BEFORE UPDATE ON canonical_sources FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. CAPTURES
CREATE TABLE captures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    canonical_source_id UUID REFERENCES canonical_sources(id) ON DELETE SET NULL,
    content_type VARCHAR(32) NOT NULL CHECK (content_type IN ('URL', 'IMAGE', 'TEXT')),
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
    error_message TEXT,
    intent VARCHAR(32) CHECK (intent IN ('WATCH', 'EXPLORE', 'REMEMBER', 'COOK', 'VISIT', 'BUY', 'LEARN')),
    category VARCHAR(64),
    original_caption TEXT,
    audio_transcript TEXT,
    notification_copies TEXT[] NOT NULL DEFAULT '{}',
    resurface_count INT NOT NULL DEFAULT 0,
    scraping_duration_ms INT,
    ai_inference_duration_ms INT,
    total_processing_duration_ms INT,
    scheduled_resurface_at TIMESTAMPTZ,
    last_resurfaced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_captures_modtime BEFORE UPDATE ON captures FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. USER COLLECTIONS
CREATE TABLE user_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    collection_id UUID REFERENCES collections(id) ON DELETE SET NULL,
    name VARCHAR(128) NOT NULL,
    category VARCHAR(64),
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_user_collections_modtime BEFORE UPDATE ON user_collections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. CAPTURE COLLECTIONS (Bridge Table M:N)
CREATE TABLE capture_collections (
    capture_id UUID NOT NULL REFERENCES captures(id) ON DELETE CASCADE,
    user_collection_id UUID NOT NULL REFERENCES user_collections(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (capture_id, user_collection_id)
);

-- 9. EXTRACTED ENTITIES
CREATE TABLE extracted_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    capture_id UUID NOT NULL REFERENCES captures(id) ON DELETE CASCADE,
    entity_type VARCHAR(32) NOT NULL CHECK (entity_type IN ('TV_SHOW', 'MOVIE', 'GITHUB_REPO', 'QUOTE', 'BOOK', 'RECIPE', 'PLACE', 'TOOL', 'IDEA')),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    external_url TEXT,
    action_cta VARCHAR(32) NOT NULL CHECK (action_cta IN ('WATCH', 'OPEN_GITHUB', 'READ', 'COOK', 'EXPLORE', 'REMEMBER', 'VISIT')),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_extracted_entities_modtime BEFORE UPDATE ON extracted_entities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 10. NOTIFICATION LOGS
CREATE TABLE notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    capture_id UUID NOT NULL REFERENCES captures(id) ON DELETE CASCADE,
    notification_type VARCHAR(32) NOT NULL,
    sent_copy TEXT NOT NULL,
    delivery_status VARCHAR(32) NOT NULL DEFAULT 'DELIVERED',
    attempt_number INT NOT NULL DEFAULT 1,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 11. INGESTION JOBS
CREATE TABLE ingestion_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    capture_id UUID NOT NULL REFERENCES captures(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type VARCHAR(32) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
    attempt_count INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 3,
    locked_at TIMESTAMPTZ,
    locked_by VARCHAR(64),
    error_detail TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_ingestion_jobs_modtime BEFORE UPDATE ON ingestion_jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- INDEXES
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_canonical_sources_hash ON canonical_sources(canonical_url_hash);
CREATE INDEX idx_captures_user_status_created ON captures(user_id, status, created_at DESC);
CREATE INDEX idx_captures_resurface ON captures(scheduled_resurface_at) WHERE status = 'COMPLETED' AND scheduled_resurface_at IS NOT NULL;
CREATE INDEX idx_extracted_entities_metadata_gin ON extracted_entities USING GIN (metadata);
CREATE INDEX idx_ingestion_jobs_pending ON ingestion_jobs(created_at ASC) WHERE status = 'PENDING';
