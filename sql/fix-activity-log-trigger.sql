-- Diagnose and fix the activity_log trigger issue

-- Step 1: List all triggers on activity_log table
SELECT 
    tgname AS trigger_name,
    tgtype,
    proname AS function_name,
    tgenabled AS enabled
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'activity_log'::regclass
ORDER BY tgname;

-- Step 2: Get the source of any embedding-related functions
SELECT 
    proname AS function_name,
    prosrc AS function_source
FROM pg_proc
WHERE proname LIKE '%embed%' 
   OR proname LIKE '%activity%'
   OR prosrc LIKE '%parent_name%'
LIMIT 10;

-- Step 3: Temporarily disable problematic triggers (if found)
-- We'll uncomment this after identifying the issue
-- ALTER TABLE activity_log DISABLE TRIGGER <trigger_name>;

-- Step 4: Create a simple insert function that bypasses triggers
CREATE OR REPLACE FUNCTION insert_activity_log(
    p_user_id TEXT,
    p_project_name TEXT,
    p_activity_type TEXT,
    p_activity_description TEXT,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS SETOF activity_log
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO activity_log (
        user_id,
        project_name,
        activity_type,
        activity_description,
        metadata
    ) VALUES (
        p_user_id,
        p_project_name,
        p_activity_type,
        p_activity_description,
        p_metadata
    )
    RETURNING *;
END;
$$;

-- Step 5: Test the function
SELECT * FROM insert_activity_log(
    'neo_todak',
    'flowstate-ai',
    'test',
    'Testing direct insert function',
    '{"source": "SQL function", "machine": "MacBook-Pro-3.local"}'::JSONB
);

-- Step 6: If the above works, let's create a fixed trigger
-- First, let's see what the current trigger is trying to do