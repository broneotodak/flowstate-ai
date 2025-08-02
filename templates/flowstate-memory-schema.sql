-- FlowState Memory System - Simplified Template
-- This creates the essential tables for personal AI memory tracking

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Core memory storage table
CREATE TABLE user_memories (
    id SERIAL PRIMARY KEY,
    user_id TEXT DEFAULT 'user',
    content TEXT NOT NULL,
    project_name TEXT,
    tool_source TEXT DEFAULT 'unknown', -- 'claude_desktop', 'cursor', 'browser', etc.
    memory_type TEXT DEFAULT 'note', -- 'note', 'code', 'bug_fix', 'feature', etc.
    embedding vector(1536),
    metadata JSONB DEFAULT '{}',
    importance INTEGER DEFAULT 5 CHECK (importance >= 1 AND importance <= 10),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- FlowState activities table (simplified)
CREATE TABLE flowstate_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT DEFAULT 'user',
    project_name TEXT,
    activity_type TEXT DEFAULT 'development', -- 'development', 'debugging', 'meeting', etc.
    description TEXT NOT NULL,
    tool_used TEXT,
    machine_name TEXT,
    duration_minutes INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Current context tracking
CREATE TABLE current_context (
    user_id TEXT PRIMARY KEY,
    project_name TEXT NOT NULL,
    current_task TEXT,
    project_emoji TEXT DEFAULT '📋',
    status TEXT DEFAULT 'active',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_user_memories_user_id ON user_memories(user_id);
CREATE INDEX idx_user_memories_created_at ON user_memories(created_at);
CREATE INDEX idx_user_memories_project ON user_memories(project_name);
CREATE INDEX idx_user_memories_embedding ON user_memories USING ivfflat (embedding vector_cosine_ops);

CREATE INDEX idx_flowstate_activities_user_id ON flowstate_activities(user_id);
CREATE INDEX idx_flowstate_activities_created_at ON flowstate_activities(created_at);
CREATE INDEX idx_flowstate_activities_project ON flowstate_activities(project_name);

-- Function to generate embeddings (placeholder - will be replaced by Edge Function)
CREATE OR REPLACE FUNCTION generate_embedding(input_text TEXT)
RETURNS vector(1536)
LANGUAGE plpgsql
AS $$
BEGIN
    -- This is a placeholder function
    -- Actual embedding generation happens in the Edge Function
    RETURN NULL;
END;
$$;

-- Function to search memories by similarity
CREATE OR REPLACE FUNCTION search_memories(
    query_embedding vector(1536),
    match_user_id TEXT DEFAULT 'user',
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id INTEGER,
    content TEXT,
    project_name TEXT,
    similarity FLOAT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.content,
        m.project_name,
        (1 - (m.embedding <=> query_embedding))::FLOAT as similarity,
        m.created_at
    FROM user_memories m
    WHERE m.user_id = match_user_id
      AND m.embedding IS NOT NULL
      AND 1 - (m.embedding <=> query_embedding) > match_threshold
    ORDER BY m.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_memories_updated_at 
    BEFORE UPDATE ON user_memories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to sync memory to FlowState activities
CREATE OR REPLACE FUNCTION sync_memory_to_flowstate()
RETURNS TRIGGER AS $$
DECLARE
    activity_description TEXT;
    detected_project TEXT;
BEGIN
    -- Only process inserts
    IF TG_OP != 'INSERT' THEN
        RETURN NEW;
    END IF;

    -- Detect project from content if not provided
    detected_project := COALESCE(
        NEW.project_name,
        CASE 
            WHEN NEW.content ILIKE '%flowstate%' THEN 'FlowState'
            WHEN NEW.content ILIKE '%claude%' THEN 'Claude Integration'
            WHEN NEW.content ILIKE '%supabase%' THEN 'Database Project'
            ELSE 'General Development'
        END
    );

    -- Generate activity description
    activity_description := CASE 
        WHEN NEW.memory_type = 'bug_fix' THEN 'Bug fixing and debugging'
        WHEN NEW.memory_type = 'feature' THEN 'Feature development'
        WHEN NEW.memory_type = 'code' THEN 'Code development'
        ELSE COALESCE(NEW.content, 'Memory activity')
    END;

    -- Insert into FlowState activities
    INSERT INTO flowstate_activities (
        user_id,
        project_name,
        activity_type,
        description,
        tool_used,
        metadata
    ) VALUES (
        NEW.user_id,
        detected_project,
        COALESCE(NEW.memory_type, 'development'),
        LEFT(activity_description, 200), -- Truncate for display
        NEW.tool_source,
        jsonb_build_object(
            'memory_id', NEW.id,
            'original_content_length', LENGTH(NEW.content),
            'sync_source', 'user_memories'
        ) || COALESCE(NEW.metadata, '{}'::jsonb)
    );

    -- Update current context
    INSERT INTO current_context (user_id, project_name, current_task, updated_at)
    VALUES (NEW.user_id, detected_project, LEFT(NEW.content, 100), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        project_name = EXCLUDED.project_name,
        current_task = EXCLUDED.current_task,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic sync
CREATE TRIGGER trigger_sync_memory_to_flowstate
    AFTER INSERT ON user_memories
    FOR EACH ROW EXECUTE FUNCTION sync_memory_to_flowstate();

-- Insert sample data to test the system
INSERT INTO user_memories (user_id, content, project_name, tool_source, memory_type) VALUES
('user', 'Setting up FlowState memory system with Supabase and OpenAI', 'FlowState', 'setup', 'note'),
('user', 'Implemented semantic search using pgvector for memory retrieval', 'FlowState', 'claude_desktop', 'feature'),
('user', 'Debugging memory sync issues between different tools', 'FlowState', 'cursor', 'bug_fix');

-- Show success message
SELECT 'FlowState Memory System installed successfully! 🎉' as status;
