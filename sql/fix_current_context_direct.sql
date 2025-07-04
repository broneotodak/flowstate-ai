-- Direct SQL fix for timezone issue
-- Run this in Supabase SQL Editor

-- First, check what we have
SELECT 
    id,
    user_id,
    project_name,
    current_task,
    last_updated,
    last_updated AT TIME ZONE 'UTC' as last_updated_utc,
    NOW() as current_time_utc,
    NOW() - last_updated::timestamp as time_diff
FROM current_context
WHERE user_id = 'neo_todak';

-- Update with proper timestamp (using NOW() which is UTC in Supabase)
UPDATE current_context
SET 
    last_updated = NOW(),
    project_name = 'flowstate-ai',
    current_task = 'Fixed timezone issue for automated tracking'
WHERE user_id = 'neo_todak';

-- Verify the update
SELECT 
    project_name,
    current_task,
    last_updated,
    to_char(last_updated, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as formatted_timestamp
FROM current_context
WHERE user_id = 'neo_todak';