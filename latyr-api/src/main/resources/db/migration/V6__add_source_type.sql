-- Migration V6: Support YOUTUBE_VIDEO source type and add source_type column to captures table

-- 1. Update canonical_sources check constraint to include YOUTUBE_VIDEO
ALTER TABLE canonical_sources DROP CONSTRAINT IF EXISTS canonical_sources_source_type_check;
ALTER TABLE canonical_sources ADD CONSTRAINT canonical_sources_source_type_check 
    CHECK (source_type IN ('INSTAGRAM_REEL', 'YOUTUBE_SHORT', 'YOUTUBE_VIDEO', 'WEB_URL', 'IMAGE'));

-- 2. Add nullable source_type column to captures
ALTER TABLE captures ADD COLUMN IF NOT EXISTS source_type VARCHAR(32);
