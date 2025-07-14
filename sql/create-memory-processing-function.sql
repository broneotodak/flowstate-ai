-- Function to process claude_desktop_memory into FlowState-friendly format
-- This extracts and enriches data for better visualization

CREATE OR REPLACE FUNCTION process_memory_for_flowstate()
RETURNS TRIGGER AS $$
BEGIN
  -- Extract activity type from memory
  NEW.metadata = jsonb_set(
    COALESCE(NEW.metadata, '{}'::jsonb),
    '{activity_type}',
    CASE 
      WHEN NEW.content ILIKE '%git commit%' THEN '"git_commit"'
      WHEN NEW.content ILIKE '%git push%' THEN '"git_push"'
      WHEN NEW.content ILIKE '%github%' THEN '"github_activity"'
      WHEN NEW.category = 'code_review' THEN '"code_review"'
      WHEN NEW.memory_type = 'technical_solution' THEN '"coding"'
      WHEN NEW.tool = 'Browser' THEN '"browser_activity"'
      ELSE '"note"'
    END::jsonb
  );

  -- Extract project name from content or metadata
  IF NEW.metadata->>'project' IS NULL THEN
    NEW.metadata = jsonb_set(
      NEW.metadata,
      '{project}',
      CASE
        WHEN NEW.content ILIKE '%flowstate%' THEN '"FlowState"'
        WHEN NEW.content ILIKE '%ctk%' OR NEW.content ILIKE '%claude-tools-kit%' THEN '"CTK"'
        WHEN NEW.content ILIKE '%neo-progress%' THEN '"Neo-Progress-Bridge"'
        WHEN NEW.category IS NOT NULL THEN to_jsonb(NEW.category)
        ELSE '"General"'
      END
    );
  END IF;

  -- Normalize machine names
  IF NEW.metadata->>'machine' IS NOT NULL THEN
    NEW.metadata = jsonb_set(
      NEW.metadata,
      '{machine}',
      CASE
        WHEN NEW.metadata->>'machine' ILIKE 'macbook%' THEN '"MacBook Pro"'
        WHEN NEW.metadata->>'machine' = 'mac' THEN '"MacBook Pro"'
        ELSE NEW.metadata->'machine'
      END
    );
  END IF;

  -- Add processed flag
  NEW.metadata = jsonb_set(
    NEW.metadata,
    '{flowstate_processed}',
    'true'::jsonb
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to process new memories
DROP TRIGGER IF EXISTS process_memory_before_insert ON claude_desktop_memory;
CREATE TRIGGER process_memory_before_insert
  BEFORE INSERT ON claude_desktop_memory
  FOR EACH ROW
  EXECUTE FUNCTION process_memory_for_flowstate();

-- Process existing unprocessed memories
UPDATE claude_desktop_memory
SET metadata = metadata || '{}'::jsonb
WHERE metadata->>'flowstate_processed' IS NULL
  AND created_at > NOW() - INTERVAL '7 days';