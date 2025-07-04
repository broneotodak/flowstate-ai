-- Fix FlowState views and add machine activity detection

-- Drop existing views to recreate them properly
DROP VIEW IF EXISTS flowstate_current_context CASCADE;
DROP VIEW IF EXISTS flowstate_machines CASCADE;
DROP VIEW IF EXISTS flowstate_activities CASCADE;

-- Recreate flowstate_activities view (this one was working)
CREATE OR REPLACE VIEW flowstate_activities AS
SELECT 
    id,
    COALESCE(metadata->>'user_id', 'neo_todak') as user_id,
    parent_name as project_name,
    COALESCE(metadata->>'activity_type', 'activity') as activity_type,
    COALESCE(metadata->>'activity_description', name) as activity_description,
    jsonb_build_object(
        'machine', COALESCE(metadata->>'machine', 'Unknown'),
        'source', COALESCE(metadata->>'source', 'Unknown'),
        'tool', COALESCE(metadata->>'tool', 'Unknown'),
        'importance', COALESCE(metadata->>'importance', 'normal')
    ) as metadata,
    created_at,
    updated_at,
    CASE WHEN embedding IS NOT NULL THEN true ELSE false END as has_embedding
FROM context_embeddings
WHERE type = 'activity'
ORDER BY created_at DESC;

-- Fix flowstate_current_context view (406 error was due to ambiguous columns)
CREATE OR REPLACE VIEW flowstate_current_context AS
WITH latest_activities AS (
    SELECT DISTINCT ON (parent_name)
        id,
        'neo_todak' as user_id,
        parent_name as project_name,
        COALESCE(metadata->>'activity_description', name) as current_task,
        COALESCE(metadata->>'activity_type', 'development') as current_phase,
        0 as progress_percentage,
        created_at as last_updated,
        created_at
    FROM context_embeddings
    WHERE type = 'activity'
    AND created_at > NOW() - INTERVAL '24 hours'
    ORDER BY parent_name, created_at DESC
)
SELECT * FROM latest_activities;

-- Fix flowstate_machines view with is_active detection
CREATE OR REPLACE VIEW flowstate_machines AS
WITH machine_stats AS (
    SELECT 
        COALESCE(metadata->>'machine', 'Unknown') as machine_name,
        MAX(created_at) as last_active,
        COUNT(*) as activity_count,
        array_agg(DISTINCT parent_name) as projects
    FROM context_embeddings
    WHERE type = 'activity'
    AND metadata->>'machine' IS NOT NULL
    GROUP BY metadata->>'machine'
)
SELECT 
    machine_name,
    'neo_todak' as user_id,
    CASE 
        WHEN machine_name LIKE '%Windows%' OR machine_name LIKE '%PC%' THEN 'desktop'
        WHEN machine_name LIKE '%Mac%' THEN 'laptop'
        ELSE 'desktop'
    END as machine_type,
    CASE 
        WHEN machine_name LIKE '%Windows%' OR machine_name LIKE '%PC%' THEN 'windows'
        WHEN machine_name LIKE '%Mac%' THEN 'macos'
        ELSE 'unknown'
    END as os,
    CASE 
        WHEN machine_name LIKE '%Office%' THEN 'office'
        WHEN machine_name LIKE '%Home%' THEN 'home'
        ELSE 'mobile'
    END as location,
    CASE 
        WHEN machine_name LIKE '%Office%' THEN '🏢'
        WHEN machine_name LIKE '%Home%' THEN '🏠'
        WHEN machine_name LIKE '%Mac%' THEN '💻'
        ELSE '🖥️'
    END as icon,
    -- Machine is active if it has logged something in the last 24 hours
    CASE 
        WHEN last_active > NOW() - INTERVAL '24 hours' THEN true
        ELSE false
    END as is_active,
    last_active,
    activity_count,
    projects[1] as last_project -- Most recent project
FROM machine_stats
ORDER BY last_active DESC;

-- Grant permissions on all views
GRANT SELECT ON flowstate_activities TO anon, authenticated, service_role;
GRANT SELECT ON flowstate_current_context TO anon, authenticated, service_role;
GRANT SELECT ON flowstate_machines TO anon, authenticated, service_role;

-- Test the views
SELECT 'Current Context:' as info;
SELECT * FROM flowstate_current_context;

SELECT chr(10) || 'Active Machines:' as info;
SELECT machine_name, is_active, last_active, activity_count 
FROM flowstate_machines 
ORDER BY is_active DESC, last_active DESC;

SELECT chr(10) || 'Recent Activities:' as info;
SELECT project_name, activity_type, activity_description, metadata->>'machine' as machine, created_at
FROM flowstate_activities 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;