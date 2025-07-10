-- Create an RPC function to fix the columns
-- Run this ONCE in Supabase SQL editor

CREATE OR REPLACE FUNCTION fix_activity_log_columns()
RETURNS void AS $$
BEGIN
    -- Add missing columns if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'activity_log' 
                   AND column_name = 'updated_at') THEN
        ALTER TABLE activity_log 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'activity_log' 
                   AND column_name = 'has_embedding') THEN
        ALTER TABLE activity_log 
        ADD COLUMN has_embedding BOOLEAN DEFAULT false;
    END IF;

    -- Update existing records
    UPDATE activity_log 
    SET updated_at = created_at 
    WHERE updated_at IS NULL;
    
    -- Note: Trigger creation is separate as it might already exist
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;