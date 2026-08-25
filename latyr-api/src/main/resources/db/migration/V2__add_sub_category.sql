-- Migration to add sub_category column to captures table
ALTER TABLE captures ADD COLUMN IF NOT EXISTS sub_category VARCHAR(128);
