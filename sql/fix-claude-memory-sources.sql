-- Fix claude_desktop_memory source and owner issues

-- Fix null owners
UPDATE claude_desktop_memory 
SET owner = 'neo_todak' 
WHERE owner IS NULL;

-- Fix sources based on content patterns
UPDATE claude_desktop_memory
SET source = CASE
  WHEN content ILIKE '%claude code%' THEN 'claude_code'
  WHEN content ILIKE '%cursor%' AND source = 'claude_desktop' THEN 'cursor'
  WHEN content ILIKE '%vscode%' AND source = 'claude_desktop' THEN 'vscode'
  WHEN content ILIKE '%n8n%' AND source = 'claude_desktop' THEN 'n8n'
  ELSE source
END,
metadata = jsonb_set(
  COALESCE(metadata, '{}'),
  '{fixed_at}',
  to_jsonb(NOW()::text)
)
WHERE source = 'claude_desktop' 
  AND (content ILIKE '%claude code%' 
    OR content ILIKE '%cursor%' 
    OR content ILIKE '%vscode%'
    OR content ILIKE '%n8n%');

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_claude_memory_source ON claude_desktop_memory(source);
CREATE INDEX IF NOT EXISTS idx_claude_memory_owner ON claude_desktop_memory(owner);
