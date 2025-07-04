-- Fix Unknown machine entries by updating them with proper machine identification

-- First, let's see what we're dealing with
SELECT 
    metadata->>'source' as source,
    metadata->>'tool' as tool,
    COUNT(*) as count,
    MIN(created_at) as first_seen,
    MAX(created_at) as last_seen
FROM context_embeddings
WHERE type = 'activity'
AND metadata->>'machine' = 'Unknown'
GROUP BY metadata->>'source', metadata->>'tool'
ORDER BY count DESC;

-- Update browser extension activities to use the hostname
-- We'll infer the machine based on timing and other activities
UPDATE context_embeddings
SET metadata = jsonb_set(
    metadata,
    '{machine}',
    CASE 
        -- If it's during Mac activity times, it's probably the Mac
        WHEN created_at::time BETWEEN '04:00:00' AND '08:00:00' THEN '"MacBook-Pro-3.local"'
        -- Otherwise might be Office PC
        ELSE '"Browser-Unknown"'
    END::jsonb
)
WHERE type = 'activity'
AND metadata->>'machine' = 'Unknown'
AND metadata->>'source' = 'browser_extension';

-- For system-monitor, we should fix it to detect the actual hostname
UPDATE context_embeddings
SET metadata = jsonb_set(
    metadata,
    '{machine}',
    '"MacBook-Pro-3.local"'::jsonb
)
WHERE type = 'activity'
AND metadata->>'machine' = 'Unknown'
AND metadata->>'source' = 'system-monitor'
AND created_at > NOW() - INTERVAL '24 hours';

-- Create a function to properly log activities with machine detection
CREATE OR REPLACE FUNCTION log_activity_with_machine(
    p_user_id TEXT,
    p_project_name TEXT,
    p_activity_type TEXT,
    p_activity_description TEXT,
    p_source TEXT,
    p_tool TEXT,
    p_machine TEXT DEFAULT NULL,
    p_additional_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS SETOF context_embeddings
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_machine TEXT;
BEGIN
    -- If machine not provided, try to detect it
    IF p_machine IS NULL OR p_machine = 'Unknown' THEN
        -- Look for recent activities from the same source to infer machine
        SELECT metadata->>'machine' INTO v_machine
        FROM context_embeddings
        WHERE type = 'activity'
        AND metadata->>'source' = p_source
        AND metadata->>'machine' != 'Unknown'
        AND created_at > NOW() - INTERVAL '1 hour'
        ORDER BY created_at DESC
        LIMIT 1;
        
        -- If still unknown, use source as machine identifier
        IF v_machine IS NULL THEN
            v_machine := p_source || '-machine';
        END IF;
    ELSE
        v_machine := p_machine;
    END IF;

    RETURN QUERY
    INSERT INTO context_embeddings (
        type,
        name,
        parent_name,
        metadata,
        embedding,
        created_at,
        updated_at
    ) VALUES (
        'activity',
        CONCAT(p_activity_type, '_', TO_CHAR(NOW(), 'YYYY-MM-DD_HH24:MI:SS')),
        p_project_name,
        jsonb_build_object(
            'user_id', p_user_id,
            'activity_type', p_activity_type,
            'activity_description', p_activity_description,
            'machine', v_machine,
            'source', p_source,
            'tool', p_tool,
            'importance', 'normal'
        ) || p_additional_metadata,
        NULL,
        NOW(),
        NOW()
    )
    RETURNING *;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION log_activity_with_machine TO anon, authenticated, service_role;

-- Show updated machine statistics
SELECT 
    metadata->>'machine' as machine,
    COUNT(*) as activity_count,
    MAX(created_at) as last_active
FROM context_embeddings
WHERE type = 'activity'
GROUP BY metadata->>'machine'
ORDER BY activity_count DESC;