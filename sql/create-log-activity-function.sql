-- Create a simple function to log activities without triggering the embedding issue
CREATE OR REPLACE FUNCTION log_activity_simple(
  p_user_id TEXT,
  p_project_name TEXT,
  p_activity_type TEXT,
  p_activity_description TEXT,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id UUID;
BEGIN
  -- Generate a new UUID
  v_id := gen_random_uuid();
  
  -- Direct insert without any triggers
  INSERT INTO activity_log (
    id,
    user_id,
    project_name,
    activity_type,
    activity_description,
    metadata,
    created_at
  ) VALUES (
    v_id,
    p_user_id,
    p_project_name,
    p_activity_type,
    p_activity_description,
    p_metadata,
    NOW()
  );
  
  RETURN v_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to log activity: %', SQLERRM;
END;
$$;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION log_activity_simple TO service_role;

-- Test the function
SELECT log_activity_simple(
  'neo_todak',
  'flowstate-ai',
  'test',
  'Testing simple activity logging function',
  '{"source": "SQL function test"}'::JSONB
);