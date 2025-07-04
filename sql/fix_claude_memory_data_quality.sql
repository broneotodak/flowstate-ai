-- Fix data quality issues in claude_desktop_memory table
-- Run these queries after reviewing the analysis results

-- First, create a backup of the current data
CREATE TABLE IF NOT EXISTS claude_desktop_memory_backup AS 
SELECT * FROM claude_desktop_memory;

-- Add a fixed_source column to track what the source should actually be
ALTER TABLE claude_desktop_memory 
ADD COLUMN IF NOT EXISTS fixed_source TEXT,
ADD COLUMN IF NOT EXISTS fixed_owner TEXT,
ADD COLUMN IF NOT EXISTS data_quality_notes TEXT;

-- Update fixed_source based on content analysis
UPDATE claude_desktop_memory
SET fixed_source = 
    CASE 
        -- VSCode patterns
        WHEN content ILIKE '%vscode%' OR content ILIKE '%visual studio code%' 
            OR metadata::text ILIKE '%vscode%' THEN 'vscode'
        
        -- Browser extension patterns
        WHEN content ILIKE '%chrome%extension%' OR content ILIKE '%browser%extension%'
            OR owner ILIKE '%extension%' THEN 'browser_extension'
        
        -- Terminal/CLI patterns
        WHEN content ILIKE '%terminal%' OR content ILIKE '%bash%' OR content ILIKE '%shell%'
            OR content ILIKE '%command%line%' THEN 'terminal'
        
        -- Git patterns
        WHEN content ILIKE '%git%commit%' OR content ILIKE '%git%push%'
            OR metadata::text ILIKE '%git%' THEN 'git'
        
        -- Claude Desktop app (legitimate uses)
        WHEN content ILIKE '%claude%desktop%' AND source = 'claude_desktop' THEN 'claude_desktop'
        
        -- FlowState specific patterns
        WHEN content ILIKE '%flowstate%' OR owner = 'flowstate' THEN 'flowstate'
        
        -- Keep original if no pattern matches
        ELSE source
    END,
    data_quality_notes = 
    CASE 
        WHEN source != fixed_source THEN 'Source corrected based on content analysis'
        ELSE NULL
    END
WHERE fixed_source IS NULL;

-- Update fixed_owner based on patterns
UPDATE claude_desktop_memory
SET fixed_owner = 
    CASE 
        -- When owner is same as source, try to extract real owner
        WHEN owner = source THEN 
            CASE
                WHEN metadata ? 'user' THEN metadata->>'user'
                WHEN metadata ? 'username' THEN metadata->>'username'
                WHEN metadata ? 'author' THEN metadata->>'author'
                ELSE 'neo_todak'  -- Default user based on other tables
            END
        
        -- When owner is a tool name, fix it
        WHEN owner IN ('vscode', 'chrome_extension', 'browser_extension', 'terminal') THEN 'neo_todak'
        
        -- Keep original if it looks like a real owner
        ELSE owner
    END,
    data_quality_notes = 
    CASE 
        WHEN owner != fixed_owner THEN 
            COALESCE(data_quality_notes || '; ', '') || 'Owner corrected'
        ELSE data_quality_notes
    END
WHERE fixed_owner IS NULL;

-- Show proposed changes before applying
SELECT 
    'Proposed changes summary' as report,
    COUNT(*) as total_records,
    COUNT(CASE WHEN source != fixed_source THEN 1 END) as source_changes,
    COUNT(CASE WHEN owner != fixed_owner THEN 1 END) as owner_changes,
    COUNT(CASE WHEN data_quality_notes IS NOT NULL THEN 1 END) as records_with_issues
FROM claude_desktop_memory;

-- Detailed view of proposed changes
SELECT 
    source as original_source,
    fixed_source as proposed_source,
    COUNT(*) as affected_records
FROM claude_desktop_memory
WHERE source != fixed_source
GROUP BY source, fixed_source
ORDER BY affected_records DESC;

-- To apply the fixes (uncomment and run after review):
/*
-- Apply the fixes
UPDATE claude_desktop_memory
SET 
    source = COALESCE(fixed_source, source),
    owner = COALESCE(fixed_owner, owner)
WHERE fixed_source IS NOT NULL OR fixed_owner IS NOT NULL;

-- Clean up temporary columns
ALTER TABLE claude_desktop_memory
DROP COLUMN IF EXISTS fixed_source,
DROP COLUMN IF EXISTS fixed_owner,
DROP COLUMN IF EXISTS data_quality_notes;
*/

-- Validation queries after fixes
SELECT 
    'After fixes - Owner/Source distribution' as validation,
    owner,
    source,
    COUNT(*) as records
FROM claude_desktop_memory
GROUP BY owner, source
ORDER BY records DESC;

-- Check for remaining issues
SELECT 
    'Remaining data quality issues' as check,
    COUNT(CASE WHEN owner IS NULL OR owner = '' THEN 1 END) as null_owners,
    COUNT(CASE WHEN source IS NULL OR source = '' THEN 1 END) as null_sources,
    COUNT(CASE WHEN owner = source THEN 1 END) as owner_equals_source,
    COUNT(CASE WHEN source = 'claude_desktop' THEN 1 END) as generic_source_remaining
FROM claude_desktop_memory;