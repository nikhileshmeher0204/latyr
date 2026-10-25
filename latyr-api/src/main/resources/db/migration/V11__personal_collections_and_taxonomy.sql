-- ==============================================================================
-- Latyr Stage 5 Migration: Personal Curated Collections & Dynamic Taxonomy
-- ==============================================================================

-- 1. Add granular tags array and custom metadata to captures
ALTER TABLE captures 
ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';

-- 2. Enhance user_collections with optional description, icon, and custom accent color
ALTER TABLE user_collections
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS icon VARCHAR(64) DEFAULT 'folder_fill',
ADD COLUMN IF NOT EXISTS color_hex VARCHAR(9) DEFAULT '#28543A';

-- 3. Create join table for Entity-level Personal Collections (M:N)
CREATE TABLE IF NOT EXISTS user_collection_entities (
    user_collection_id UUID NOT NULL REFERENCES user_collections(id) ON DELETE CASCADE,
    entity_id UUID NOT NULL REFERENCES extracted_entities(id) ON DELETE CASCADE,
    item_order INT NOT NULL DEFAULT 0,
    added_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_collection_id, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_uce_collection_order 
ON user_collection_entities(user_collection_id, item_order ASC, added_at DESC);

CREATE INDEX IF NOT EXISTS idx_uce_entity 
ON user_collection_entities(entity_id);

-- 4. Clean and normalize existing captures taxonomy
-- First, normalize null or empty categories
UPDATE captures
SET category = 'General',
    sub_category = 'General',
    tags = ARRAY['General']
WHERE category IS NULL OR category = '';

-- A. Entertainment: Standardize format as sub_category, move genres/keywords to tags
UPDATE captures
SET sub_category = 'TV Series',
    tags = ARRAY['Mystery', 'Thriller', 'True Crime']
WHERE category ILIKE 'Entertainment'
  AND (sub_category ILIKE '%series%' OR sub_category ILIKE '%show%');

UPDATE captures
SET sub_category = 'Documentaries',
    tags = ARRAY['Crime', 'True Crime', 'Docuseries']
WHERE category ILIKE 'Entertainment'
  AND sub_category ILIKE '%documentary%'
  AND sub_category NOT ILIKE '%series%';

UPDATE captures
SET sub_category = 'Movies',
    tags = CASE 
        WHEN sub_category ILIKE '%psychological%' THEN ARRAY['Psychological', 'Thriller', 'Mystery']
        WHEN sub_category ILIKE '%sci-fi%' OR sub_category ILIKE '%time travel%' THEN ARRAY['Sci-Fi', 'Mystery', 'Time Travel']
        WHEN sub_category ILIKE '%horror%' THEN ARRAY['Horror', 'Thriller']
        WHEN sub_category ILIKE '%crime%' OR sub_category ILIKE '%thriller%' THEN ARRAY['Crime', 'Thriller']
        ELSE ARRAY['Movies']
    END
WHERE category ILIKE 'Entertainment'
  AND sub_category != 'TV Series'
  AND sub_category != 'Documentaries';

-- B. Tech: Standardize Developer Tools, AI Tools, Cybersecurity, Cloud Architecture
UPDATE captures
SET sub_category = 'AI Tools',
    tags = ARRAY['AI', 'LLM', 'Productivity']
WHERE category ILIKE 'Tech'
  AND (sub_category ILIKE '%ai%' OR sub_category ILIKE '%llm%');

UPDATE captures
SET sub_category = 'Developer Tools',
    tags = ARRAY['Developer Tools', 'Open Source', 'GitHub']
WHERE category ILIKE 'Tech'
  AND (sub_category ILIKE '%developer%' OR sub_category ILIKE '%github%' OR sub_category ILIKE '%software%' OR sub_category ILIKE '%news%');

UPDATE captures
SET sub_category = 'Cybersecurity',
    tags = ARRAY['Cybersecurity', 'Tools', 'Security']
WHERE category ILIKE 'Tech'
  AND sub_category ILIKE '%cyber%';

UPDATE captures
SET sub_category = 'Cloud Architecture',
    tags = ARRAY['Cloud', 'DevOps', 'System Design']
WHERE category ILIKE 'Tech'
  AND (sub_category ILIKE '%cloud%' OR sub_category ILIKE '%system design%' OR sub_category ILIKE '%web dev%');

UPDATE captures
SET sub_category = 'Data & Analytics',
    tags = ARRAY['Data Analysis', 'Python', 'Analytics']
WHERE category ILIKE 'Tech'
  AND sub_category ILIKE '%data%';

-- C. Learning: Standardize Career & Interviews, Certifications, Strategy
UPDATE captures
SET sub_category = 'Career & Interviews',
    tags = ARRAY['Job Search', 'Interview Tips', 'Career']
WHERE category ILIKE 'Learning'
  AND (sub_category ILIKE '%interview%' OR sub_category ILIKE '%job%' OR sub_category ILIKE '%career%' OR sub_category ILIKE '%remote%');

UPDATE captures
SET sub_category = 'Certifications',
    tags = ARRAY['Certifications', 'AI', 'Learning']
WHERE category ILIKE 'Learning'
  AND sub_category ILIKE '%cert%';

UPDATE captures
SET sub_category = 'Business Strategy',
    tags = ARRAY['Entrepreneurship', 'Strategy', 'Mindset']
WHERE category ILIKE 'Learning'
  AND (sub_category ILIKE '%entrepreneur%' OR sub_category ILIKE '%business%' OR sub_category ILIKE '%marketing%');

-- D. Food: Standardize Recipes
UPDATE captures
SET sub_category = 'Recipes',
    tags = ARRAY['Shawarma', 'Street Food', 'Cooking']
WHERE category ILIKE 'Food'
  AND (sub_category ILIKE '%recipe%' OR sub_category ILIKE '%shawarma%');

-- E. Lifestyle: Standardize Networking
UPDATE captures
SET sub_category = 'Networking',
    tags = ARRAY['Networking', 'Connections', 'Growth']
WHERE category ILIKE 'Lifestyle'
  AND sub_category ILIKE '%network%';

-- F. Catch-all for remaining unhandled sub_categories
UPDATE captures
SET sub_category = category
WHERE sub_category IS NULL OR sub_category = '';

UPDATE captures
SET tags = ARRAY[sub_category]
WHERE tags = '{}' AND sub_category IS NOT NULL AND sub_category != '';
