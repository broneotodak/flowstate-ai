-- Drop and recreate flowstate_activities view to ensure it shows all records

-- First, let's see the current view definition
-- SELECT pg_get_viewdef('flowstate_activities', true);

-- Option 1: If flowstate_activities is just a simple view of activity_log
DROP VIEW IF EXISTS flowstate_activities CASCADE;

CREATE OR REPLACE VIEW flowstate_activities AS
SELECT 
    id,
    user_id,
    project_name,
    activity_type,
    activity_description,
    metadata,
    created_at,
    COALESCE(updated_at, created_at) as updated_at,
    COALESCE(has_embedding, false) as has_embedding
FROM activity_log;

-- Grant permissions
GRANT SELECT ON flowstate_activities TO authenticated;
GRANT SELECT ON flowstate_activities TO anon;

-- Test the view
SELECT COUNT(*) as total_records,
       COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_count,
       COUNT(CASE WHEN activity_type = 'git_commit' THEN 1 END) as commit_count
FROM flowstate_activities;