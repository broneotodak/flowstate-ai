-- Comprehensive fix for all Unknown machine entries

-- First, let's analyze what these Unknown entries are
SELECT 
    DATE(created_at) as date,
    metadata->>'source' as source,
    metadata->>'tool' as tool,
    parent_name as project,
    COUNT(*) as count
FROM context_embeddings
WHERE type = 'activity'
AND metadata->>'machine' = 'Unknown'
GROUP BY DATE(created_at), metadata->>'source', metadata->>'tool', parent_name
ORDER BY date DESC, count DESC;

-- Update based on patterns and context
UPDATE context_embeddings
SET metadata = jsonb_set(
    metadata,
    '{machine}',
    CASE 
        -- July 2nd activities - likely from initial setup
        WHEN created_at::date = '2025-07-02' AND parent_name = 'TODAK' THEN '"Initial-Setup-Machine"'::jsonb
        WHEN created_at::date = '2025-07-02' AND parent_name = 'FlowState' THEN '"Initial-Setup-Machine"'::jsonb
        
        -- Browser extension activities
        WHEN metadata->>'source' = 'browser_extension' THEN '"Browser-Machine"'::jsonb
        
        -- System monitor activities
        WHEN metadata->>'source' = 'system-monitor' THEN '"MacBook-Pro-3.local"'::jsonb
        
        -- Git activities are likely from the machine where git is running
        WHEN metadata->>'tool' LIKE '%git%' THEN '"MacBook-Pro-3.local"'::jsonb
        
        -- Default: mark as historical unknown
        ELSE '"Historical-Unknown"'::jsonb
    END
)
WHERE type = 'activity'
AND metadata->>'machine' = 'Unknown';

-- Update flowstate_machines view to filter out non-real machines
DROP VIEW IF EXISTS flowstate_machines CASCADE;

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
    -- Filter out placeholder machines
    AND metadata->>'machine' NOT IN ('Unknown', 'Historical-Unknown', 'Initial-Setup-Machine')
    GROUP BY metadata->>'machine'
)
SELECT 
    machine_name,
    'neo_todak' as user_id,
    CASE 
        WHEN machine_name LIKE '%Windows%' OR machine_name LIKE '%PC%' THEN 'desktop'
        WHEN machine_name LIKE '%Mac%' THEN 'laptop'
        WHEN machine_name = 'Browser-Machine' THEN 'browser'
        ELSE 'desktop'
    END as machine_type,
    CASE 
        WHEN machine_name LIKE '%Windows%' OR machine_name LIKE '%PC%' THEN 'windows'
        WHEN machine_name LIKE '%Mac%' THEN 'macos'
        WHEN machine_name = 'Browser-Machine' THEN 'web'
        ELSE 'unknown'
    END as os,
    CASE 
        WHEN machine_name LIKE '%Office%' THEN 'office'
        WHEN machine_name LIKE '%Home%' THEN 'home'
        WHEN machine_name = 'Browser-Machine' THEN 'cloud'
        ELSE 'mobile'
    END as location,
    CASE 
        WHEN machine_name LIKE '%Office%' THEN '🏢'
        WHEN machine_name LIKE '%Home%' THEN '🏠'
        WHEN machine_name LIKE '%Mac%' THEN '💻'
        WHEN machine_name = 'Browser-Machine' THEN '🌐'
        ELSE '🖥️'
    END as icon,
    CASE 
        WHEN last_active > NOW() - INTERVAL '24 hours' THEN true
        ELSE false
    END as is_active,
    last_active,
    activity_count,
    projects[1] as last_project
FROM machine_stats
ORDER BY last_active DESC;

-- Grant permissions
GRANT SELECT ON flowstate_machines TO anon, authenticated, service_role;

-- Show final results
SELECT 'Updated Machine Statistics:' as info;
SELECT 
    metadata->>'machine' as machine,
    COUNT(*) as activity_count,
    MAX(created_at) as last_active,
    MIN(created_at) as first_active
FROM context_embeddings
WHERE type = 'activity'
GROUP BY metadata->>'machine'
ORDER BY MAX(created_at) DESC;

-- Show current active machines (real machines only)
SELECT chr(10) || 'Active Real Machines:' as info;
SELECT * FROM flowstate_machines;