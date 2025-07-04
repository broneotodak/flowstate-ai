-- Search for Kenal Admin project memories in pgvector database
-- Run these queries in your Supabase SQL editor

-- 1. Search context_embeddings table for Kenal-related entries
SELECT 
    type,
    name,
    parent_name,
    text,
    metadata,
    created_at,
    updated_at
FROM context_embeddings
WHERE 
    name ILIKE '%kenal%' 
    OR parent_name ILIKE '%kenal%'
    OR text ILIKE '%kenal%'
    OR metadata::text ILIKE '%kenal%'
ORDER BY created_at DESC;

-- 2. Search activity_log for Kenal Admin activities
SELECT 
    id,
    user_id,
    project_name,
    activity_type,
    activity_description,
    metadata,
    created_at
FROM activity_log
WHERE 
    project_name ILIKE '%kenal%'
    OR activity_description ILIKE '%kenal%'
    OR metadata::text ILIKE '%kenal%'
ORDER BY created_at DESC
LIMIT 100;

-- 3. Check for Cursor AI activities in the system
SELECT 
    id,
    user_id,
    project_name,
    activity_type,
    activity_description,
    metadata,
    created_at
FROM activity_log
WHERE 
    activity_type = 'ai_conversation'
    AND (
        metadata->>'tool' = 'cursor'
        OR metadata->>'source' = 'cursor'
        OR activity_description ILIKE '%cursor%'
    )
ORDER BY created_at DESC
LIMIT 50;

-- 4. Check current_context for Kenal Admin
SELECT 
    id,
    user_id,
    project_name,
    current_task,
    current_phase,
    progress_percentage,
    last_updated,
    created_at
FROM current_context
WHERE 
    project_name ILIKE '%kenal%'
    OR current_task ILIKE '%kenal%';

-- 5. Search for any recent AI conversations that might mention Kenal
SELECT 
    type,
    name,
    parent_name,
    text,
    metadata,
    created_at
FROM context_embeddings
WHERE 
    type = 'ai_conversation'
    AND created_at > NOW() - INTERVAL '7 days'
    AND (
        text ILIKE '%kenal%'
        OR metadata::text ILIKE '%kenal%'
    )
ORDER BY created_at DESC;

-- 6. Get summary of all projects in activity_log
SELECT 
    project_name,
    COUNT(*) as activity_count,
    MIN(created_at) as first_activity,
    MAX(created_at) as last_activity,
    array_agg(DISTINCT activity_type) as activity_types
FROM activity_log
WHERE project_name IS NOT NULL
GROUP BY project_name
ORDER BY last_activity DESC;

-- 7. Check for any embeddings with Kenal in metadata
SELECT 
    type,
    name,
    parent_name,
    metadata,
    created_at
FROM context_embeddings
WHERE metadata IS NOT NULL
AND metadata::text ILIKE '%kenal%'
ORDER BY created_at DESC;