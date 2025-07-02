-- Fix activities table and RLS policies
-- Run this in Supabase SQL Editor

-- First, check if table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'activities'
);

-- If table doesn't exist, create it
CREATE TABLE IF NOT EXISTS activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL DEFAULT 'neo_todak',
    activity_type TEXT NOT NULL,
    description TEXT NOT NULL,
    project_name TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own activities" ON activities;
DROP POLICY IF EXISTS "Users can insert their own activities" ON activities;
DROP POLICY IF EXISTS "Service role can do everything" ON activities;

-- Disable RLS temporarily for testing
ALTER TABLE activities DISABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_created ON activities(created_at DESC);

-- Insert test data
INSERT INTO activities (user_id, activity_type, description, project_name) VALUES
    ('neo_todak', 'test', 'Testing activities table', 'FlowState'),
    ('neo_todak', 'manual', 'Manual activity entry', 'FlowState')
ON CONFLICT DO NOTHING;

-- Check if data was inserted
SELECT * FROM activities WHERE user_id = 'neo_todak' ORDER BY created_at DESC LIMIT 5;