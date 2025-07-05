-- Check if flowstate_activities is a view or table
SELECT 
    schemaname,
    tablename as name,
    'table' as type
FROM pg_tables
WHERE tablename = 'flowstate_activities'
UNION
SELECT 
    schemaname,
    viewname as name,
    'view' as type
FROM pg_views
WHERE viewname = 'flowstate_activities';

-- If it's a view, show its definition
SELECT pg_get_viewdef('flowstate_activities', true);

-- Check activity counts
SELECT 
    'activity_log' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_count,
    COUNT(CASE WHEN activity_type = 'git_commit' THEN 1 END) as commit_count
FROM activity_log
UNION ALL
SELECT 
    'flowstate_activities' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_count,
    COUNT(CASE WHEN activity_type = 'git_commit' THEN 1 END) as commit_count
FROM flowstate_activities;