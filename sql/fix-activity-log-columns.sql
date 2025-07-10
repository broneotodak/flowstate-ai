-- Add missing columns to activity_log if they don't exist
ALTER TABLE activity_log 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE activity_log 
ADD COLUMN IF NOT EXISTS has_embedding BOOLEAN DEFAULT false;

-- Update existing records
UPDATE activity_log 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Create trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_activity_log_updated_at 
BEFORE UPDATE ON activity_log 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();