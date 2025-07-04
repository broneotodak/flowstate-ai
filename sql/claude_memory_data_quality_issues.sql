-- Data Quality Issues Analysis for claude_desktop_memory table
-- Focus on owner and source column problems

-- Show the actual values being used for owner and source
-- This helps identify if tools are misusing these fields
SELECT 
    'Unique owner-source combinations' as analysis,
    owner,
    source,
    COUNT(*) as record_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage_of_total
FROM claude_desktop_memory
GROUP BY owner, source
ORDER BY record_count DESC;

-- Identify records where source might be incorrect
-- Looking for patterns where source doesn't match the actual tool
SELECT 
    'Potential source mismatches' as issue_type,
    owner,
    source,
    COUNT(*) as count,
    -- Check content for clues about actual source
    CASE 
        WHEN content ILIKE '%vscode%' THEN 'Possibly VSCode'
        WHEN content ILIKE '%chrome%' OR content ILIKE '%browser%' THEN 'Possibly Browser'
        WHEN content ILIKE '%terminal%' OR content ILIKE '%bash%' THEN 'Possibly Terminal'
        WHEN content ILIKE '%git%' THEN 'Possibly Git'
        WHEN metadata::text ILIKE '%vscode%' THEN 'Metadata suggests VSCode'
        WHEN metadata::text ILIKE '%browser%' THEN 'Metadata suggests Browser'
        ELSE 'Unknown actual source'
    END as likely_actual_source
FROM claude_desktop_memory
WHERE source = 'claude_desktop'  -- All using same source
GROUP BY owner, source, likely_actual_source
ORDER BY count DESC;

-- Check if owner field is being used to store tool/source info instead
SELECT 
    'Owner field analysis' as analysis,
    owner,
    COUNT(*) as records,
    COUNT(DISTINCT source) as different_sources_used,
    STRING_AGG(DISTINCT source, ', ') as sources,
    -- Does owner name suggest it's actually a tool identifier?
    CASE
        WHEN owner ILIKE '%extension%' THEN 'Likely browser extension'
        WHEN owner ILIKE '%vscode%' THEN 'Likely VSCode'
        WHEN owner ILIKE '%editor%' THEN 'Likely code editor'
        WHEN owner ILIKE '%terminal%' THEN 'Likely terminal'
        WHEN owner = 'claude_desktop' THEN 'Owner same as source - likely error'
        ELSE 'Appears to be actual owner/user'
    END as owner_type_assessment
FROM claude_desktop_memory
GROUP BY owner
ORDER BY records DESC;

-- Find records where owner and source are identical (data quality issue)
SELECT 
    'Owner equals Source' as issue,
    owner,
    source,
    COUNT(*) as count,
    MIN(created_at) as first_occurrence,
    MAX(created_at) as last_occurrence
FROM claude_desktop_memory
WHERE owner = source
GROUP BY owner, source;

-- Analyze metadata to understand true data sources
SELECT 
    'Metadata analysis for source identification' as analysis,
    owner,
    source,
    COUNT(*) as records,
    -- Extract tool info from metadata if present
    COUNT(CASE WHEN metadata ? 'tool' THEN 1 END) as has_tool_metadata,
    COUNT(CASE WHEN metadata ? 'application' THEN 1 END) as has_application_metadata,
    COUNT(CASE WHEN metadata ? 'source_type' THEN 1 END) as has_source_type_metadata,
    -- Sample metadata keys to understand structure
    jsonb_object_keys(metadata) as metadata_keys
FROM claude_desktop_memory
WHERE metadata IS NOT NULL AND metadata != '{}'
GROUP BY owner, source, metadata_keys
ORDER BY records DESC
LIMIT 20;

-- Recommendations query - identify what should be fixed
WITH data_issues AS (
    SELECT 
        id,
        owner,
        source,
        CASE
            WHEN owner IS NULL OR owner = '' THEN 'Missing owner'
            WHEN source IS NULL OR source = '' THEN 'Missing source'
            WHEN owner = source THEN 'Owner same as source'
            WHEN source = 'claude_desktop' AND content NOT ILIKE '%claude%desktop%' THEN 'Generic source name'
            ELSE 'OK'
        END as issue
    FROM claude_desktop_memory
)
SELECT 
    issue,
    COUNT(*) as affected_records,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM claude_desktop_memory), 2) as percentage_of_total,
    STRING_AGG(DISTINCT owner, ', ' ORDER BY owner) as affected_owners
FROM data_issues
WHERE issue != 'OK'
GROUP BY issue
ORDER BY affected_records DESC;

-- Show a sample of problematic records for manual inspection
SELECT 
    'Sample problematic records' as section,
    id,
    owner,
    source,
    SUBSTRING(content, 1, 100) as content_preview,
    jsonb_pretty(metadata) as metadata,
    created_at
FROM claude_desktop_memory
WHERE 
    owner = source OR
    source = 'claude_desktop' OR
    owner IS NULL OR
    source IS NULL
ORDER BY created_at DESC
LIMIT 10;