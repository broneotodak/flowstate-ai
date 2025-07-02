-- Add model column to context_embeddings table if it doesn't exist
ALTER TABLE context_embeddings 
ADD COLUMN IF NOT EXISTS model TEXT DEFAULT 'text-embedding-3-small';

-- Update existing rows to have the default model
UPDATE context_embeddings 
SET model = 'text-embedding-3-small' 
WHERE model IS NULL;