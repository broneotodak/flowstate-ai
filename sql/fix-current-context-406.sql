-- Fix 406 error for flowstate_current_context
-- The issue: dashboard expects single row but view returns multiple rows

-- Option 1: Modify dashboard to handle multiple rows (RECOMMENDED)
-- The view is already correct, returning one row per active project

-- Option 2: Create a different view that returns only the most recent project
DROP VIEW IF EXISTS flowstate_latest_context CASCADE;

CREATE OR REPLACE VIEW flowstate_latest_context AS
SELECT 
    id,
    'neo_todak' as user_id,
    project_name,
    current_task,
    current_phase,
    0 as progress_percentage,
    last_updated,
    created_at
FROM (
    SELECT DISTINCT ON (parent_name)
        id,
        parent_name as project_name,
        COALESCE(metadata->>'activity_description', name) as current_task,
        COALESCE(metadata->>'activity_type', 'development') as current_phase,
        created_at as last_updated,
        created_at
    FROM context_embeddings
    WHERE type = 'activity'
    AND created_at > NOW() - INTERVAL '24 hours'
    ORDER BY parent_name, created_at DESC
) as contexts
ORDER BY last_updated DESC
LIMIT 1;

-- Grant permissions
GRANT SELECT ON flowstate_latest_context TO anon, authenticated, service_role;

-- Test both views
SELECT 'Multiple contexts (all active projects):' as info;
SELECT project_name, current_task, last_updated FROM flowstate_current_context;

SELECT chr(10) || 'Single latest context:' as info;
SELECT * FROM flowstate_latest_context;