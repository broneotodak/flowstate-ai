-- Create activities table for FlowState tracking
-- This table stores all user activities from various sources (git, browser, AI tools)

CREATE TABLE IF NOT EXISTS activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL DEFAULT 'neo_todak',
    activity_type TEXT NOT NULL, -- 'git_commit', 'git_push', 'browser_activity', 'ai_conversation', etc
    description TEXT NOT NULL,
    project_name TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_project ON activities(project_name);
CREATE INDEX IF NOT EXISTS idx_activities_type ON activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_activities_created ON activities(created_at DESC);

-- Enable Row Level Security
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own activities" ON activities
    FOR SELECT USING (auth.uid()::text = user_id OR user_id = 'neo_todak');

CREATE POLICY "Users can insert their own activities" ON activities
    FOR INSERT WITH CHECK (auth.uid()::text = user_id OR user_id = 'neo_todak');

CREATE POLICY "Service role can do everything" ON activities
    FOR ALL USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT, INSERT ON activities TO anon, authenticated;
GRANT ALL ON activities TO service_role;

-- Create updated_at trigger
CREATE TRIGGER update_activities_updated_at
    BEFORE UPDATE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add some sample data to test
INSERT INTO activities (user_id, activity_type, description, project_name) VALUES
    ('neo_todak', 'system', 'Activities table created', 'FlowState'),
    ('neo_todak', 'git_commit', 'Initial FlowState setup', 'FlowState')
ON CONFLICT DO NOTHING;