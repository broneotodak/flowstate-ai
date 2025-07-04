-- Update Claude pgvector memory with FlowState progress
-- Run this in your todak-ai Supabase SQL editor

-- Insert memory about FlowState automated tracking implementation
INSERT INTO context_embeddings (
    type,
    name,
    parent_name,
    metadata,
    created_at,
    updated_at
) VALUES (
    'ai_conversation',
    'FlowState Automated Tracking Implementation - July 2, 2025',
    'FlowState',
    jsonb_build_object(
        'session_date', '2025-07-02',
        'achievements', ARRAY[
            'Implemented AI embeddings with pgvector for semantic search',
            'Created and deployed git hooks for automatic commit tracking',
            'Fixed timezone bug showing 8h ago instead of current time',
            'Built Chrome browser extension for tab-based project detection',
            'Created GitHub webhook Edge Function (ready to deploy)',
            'Dashboard now updates in real-time with every commit',
            'Fixed refreshGitHub event handler error'
        ],
        'key_learnings', ARRAY[
            'Timestamps without Z suffix are interpreted as local time by JavaScript',
            'Git hooks are the most reliable way to track development activity',
            'Browser extensions need proper manifest configuration with icons',
            'Supabase returns timestamps without timezone info by default'
        ],
        'next_steps', ARRAY[
            'Fix browser extension service key handling',
            'Deploy GitHub webhooks for PR tracking',
            'Build AI memory tracker for Claude conversations',
            'Add analytics dashboard for time tracking'
        ],
        'files_created', ARRAY[
            'install-flowstate-git-hooks.sh',
            'browser-extension/*',
            'supabase/functions/generate-embeddings/*',
            'supabase/functions/github-webhook/*',
            'Multiple debugging and fixing tools'
        ],
        'current_status', 'Git hooks working perfectly, dashboard showing real-time updates'
    ),
    NOW(),
    NOW()
);

-- Generate embedding for this memory (if Edge Function is deployed)
-- This would be called automatically if triggers are set up
SELECT 
    'Run generate-embeddings Edge Function for this new memory' as action,
    'Or wait for automatic trigger if configured' as alternative;

-- Verify insertion
SELECT 
    type,
    name,
    parent_name,
    metadata->>'session_date' as session_date,
    metadata->'achievements' as achievements,
    created_at
FROM context_embeddings
WHERE type = 'ai_conversation'
AND parent_name = 'FlowState'
ORDER BY created_at DESC
LIMIT 1;