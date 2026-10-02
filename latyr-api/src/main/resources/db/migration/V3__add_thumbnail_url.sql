-- Add thumbnail_url to captures and canonical_sources
ALTER TABLE captures ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(2048);
ALTER TABLE canonical_sources ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(2048);
