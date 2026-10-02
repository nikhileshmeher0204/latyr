-- Flyway migration V4: Add AI-generated short title to captures table
ALTER TABLE captures ADD COLUMN IF NOT EXISTS title TEXT;
