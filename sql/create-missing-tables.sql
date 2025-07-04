-- Create missing tables for FlowState
-- Run this in Supabase SQL editor

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done', 'cancelled')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date TIMESTAMPTZ,
    assigned_to TEXT DEFAULT 'neo_todak',
    created_by TEXT DEFAULT 'neo_todak',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Time tracking table
CREATE TABLE IF NOT EXISTS time_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT DEFAULT 'neo_todak',
    project_name TEXT,
    task_id UUID REFERENCES tasks(id),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN end_time IS NOT NULL THEN 
                EXTRACT(EPOCH FROM (end_time - start_time)) / 60
            ELSE NULL
        END
    ) STORED,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Active sessions (for tracking current work sessions)
CREATE TABLE IF NOT EXISTS active_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT DEFAULT 'neo_todak',
    project_name TEXT,
    session_type TEXT,
    start_time TIMESTAMPTZ DEFAULT NOW(),
    last_activity TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true
);

-- Project status
CREATE TABLE IF NOT EXISTS project_status (
    project_name TEXT PRIMARY KEY,
    status TEXT DEFAULT 'active' CHECK (status IN ('planning', 'active', 'paused', 'completed', 'archived')),
    health TEXT DEFAULT 'good' CHECK (health IN ('good', 'at_risk', 'critical')),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    last_activity TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Project phases
CREATE TABLE IF NOT EXISTS project_phases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_name TEXT NOT NULL,
    phase_name TEXT NOT NULL,
    phase_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed')),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Project owners
CREATE TABLE IF NOT EXISTS project_owners (
    project_name TEXT NOT NULL,
    user_id TEXT NOT NULL,
    role TEXT DEFAULT 'developer' CHECK (role IN ('owner', 'developer', 'viewer')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (project_name, user_id)
);

-- GitHub commits (separate from activity_log for detailed tracking)
CREATE TABLE IF NOT EXISTS github_commits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_name TEXT,
    repo_name TEXT,
    commit_sha TEXT UNIQUE,
    commit_message TEXT,
    author_name TEXT,
    author_email TEXT,
    commit_date TIMESTAMPTZ,
    files_changed INTEGER,
    additions INTEGER,
    deletions INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_name);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_time_tracking_project ON time_tracking(project_name);
CREATE INDEX IF NOT EXISTS idx_time_tracking_user ON time_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_active_sessions_user ON active_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_github_commits_project ON github_commits(project_name);

-- Enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_phases ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE github_commits ENABLE ROW LEVEL SECURITY;

-- Create policies (allow all for service role)
CREATE POLICY "Service role has full access" ON tasks FOR ALL USING (true);
CREATE POLICY "Service role has full access" ON time_tracking FOR ALL USING (true);
CREATE POLICY "Service role has full access" ON active_sessions FOR ALL USING (true);
CREATE POLICY "Service role has full access" ON project_status FOR ALL USING (true);
CREATE POLICY "Service role has full access" ON project_phases FOR ALL USING (true);
CREATE POLICY "Service role has full access" ON project_owners FOR ALL USING (true);
CREATE POLICY "Service role has full access" ON github_commits FOR ALL USING (true);

-- Insert initial data
INSERT INTO project_owners (project_name, user_id, role) VALUES
    ('flowstate-ai', 'neo_todak', 'owner'),
    ('flowstate-ai-github', 'neo_todak', 'owner')
ON CONFLICT DO NOTHING;

INSERT INTO project_status (project_name, status, health, progress_percentage) VALUES
    ('flowstate-ai', 'active', 'good', 75),
    ('flowstate-ai-github', 'active', 'good', 75)
ON CONFLICT DO NOTHING;

INSERT INTO project_phases (project_name, phase_name, phase_order, status) VALUES
    ('flowstate-ai', 'Planning', 1, 'completed'),
    ('flowstate-ai', 'MVP Development', 2, 'completed'),
    ('flowstate-ai', 'Integration', 3, 'active'),
    ('flowstate-ai', 'Enhancement', 4, 'pending')
ON CONFLICT DO NOTHING;