-- Create proper FlowState views that read from activity_log table

-- Drop the incorrect view
DROP VIEW IF EXISTS flowstate_activities CASCADE;

-- Create flowstate_activities view from the ACTUAL activity_log table
CREATE OR REPLACE VIEW flowstate_activities AS
SELECT 
    id,
    user_id,
    project_name,
    activity_type,
    activity_description,
    metadata,
    created_at,
    created_at as updated_at,  -- activity_log doesn't have updated_at
    false as has_embedding     -- activity_log doesn't have embeddings
FROM activity_log
WHERE user_id = 'neo_todak'
ORDER BY created_at DESC;

-- Also create a view for current context based on recent activity_log
CREATE OR REPLACE VIEW flowstate_current_context AS
WITH recent_project_activities AS (
    SELECT DISTINCT ON (project_name)
        gen_random_uuid() as id,  -- Generate ID for view
        user_id,
        project_name,
        activity_description as current_task,
        activity_type as current_phase,
        0 as progress_percentage,
        created_at as last_updated,
        created_at
    FROM activity_log
    WHERE user_id = 'neo_todak'
    AND created_at > NOW() - INTERVAL '8 hours'
    AND activity_type NOT IN ('browser_activity', 'memory_sync')
    ORDER BY project_name, created_at DESC
)
SELECT * FROM recent_project_activities;

-- Create machines view from user_machines table (the actual machines table)
CREATE OR REPLACE VIEW flowstate_machines AS
SELECT 
    gen_random_uuid() as id,  -- Add ID for compatibility
    user_id,
    machine_name,
    machine_type,
    os,
    location,
    icon,
    is_active,
    last_active,
    created_at,
    activity_count,
    metadata
FROM user_machines
WHERE user_id = 'neo_todak'
ORDER BY last_active DESC;

-- Grant permissions
GRANT SELECT ON flowstate_activities TO anon, authenticated, service_role;
GRANT SELECT ON flowstate_current_context TO anon, authenticated, service_role;
GRANT SELECT ON flowstate_machines TO anon, authenticated, service_role;

-- Test the views
SELECT 'Testing flowstate_activities view:' as info;
SELECT COUNT(*) as total_activities FROM flowstate_activities;

SELECT chr(10) || 'Recent activities:' as info;
SELECT created_at, activity_type, project_name, activity_description 
FROM flowstate_activities 
WHERE created_at > NOW() - INTERVAL '2 hours'
ORDER BY created_at DESC
LIMIT 5;

SELECT chr(10) || 'Current contexts:' as info;
SELECT project_name, current_task, last_updated
FROM flowstate_current_context
ORDER BY last_updated DESC;