-- Comprehensive analysis of claude_desktop_memory table data quality issues
-- Run this script in Supabase SQL editor

-- 1. Check table structure (columns, types)
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'claude_desktop_memory'
ORDER BY ordinal_position;

-- 2. Get sample data showing the owner and source columns
SELECT 
    id,
    owner,
    source,
    content,
    metadata,
    created_at
FROM claude_desktop_memory
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check for null/incorrect values in owner and source columns
SELECT 
    'NULL owner values' as issue,
    COUNT(*) as count
FROM claude_desktop_memory
WHERE owner IS NULL
UNION ALL
SELECT 
    'NULL source values' as issue,
    COUNT(*) as count
FROM claude_desktop_memory
WHERE source IS NULL
UNION ALL
SELECT 
    'Empty string owner values' as issue,
    COUNT(*) as count
FROM claude_desktop_memory
WHERE owner = ''
UNION ALL
SELECT 
    'Empty string source values' as issue,
    COUNT(*) as count
FROM claude_desktop_memory
WHERE source = '';

-- 4. Count how many different sources are recorded
SELECT 
    source,
    COUNT(*) as record_count,
    COUNT(DISTINCT owner) as unique_owners,
    MIN(created_at) as first_seen,
    MAX(created_at) as last_seen
FROM claude_desktop_memory
GROUP BY source
ORDER BY record_count DESC;

-- 5. Check if different tools are all using "claude_desktop" as source incorrectly
-- This query shows the pattern of owner-source combinations
SELECT 
    owner,
    source,
    COUNT(*) as record_count,
    COUNT(DISTINCT DATE(created_at)) as days_active,
    MIN(created_at) as first_record,
    MAX(created_at) as last_record,
    -- Sample of content to understand what type of data each owner/source stores
    SUBSTRING(MIN(content), 1, 100) as sample_content
FROM claude_desktop_memory
GROUP BY owner, source
ORDER BY record_count DESC;

-- Additional analysis: Check metadata structure
SELECT 
    owner,
    source,
    jsonb_typeof(metadata) as metadata_type,
    COUNT(*) as count
FROM claude_desktop_memory
GROUP BY owner, source, jsonb_typeof(metadata)
ORDER BY count DESC;

-- Check for potential duplicate entries
WITH potential_duplicates AS (
    SELECT 
        owner,
        source,
        content,
        COUNT(*) as duplicate_count
    FROM claude_desktop_memory
    GROUP BY owner, source, content
    HAVING COUNT(*) > 1
)
SELECT 
    'Potential duplicate entries' as issue,
    COUNT(*) as unique_duplicate_sets,
    SUM(duplicate_count) as total_duplicate_records
FROM potential_duplicates;

-- Analyze data distribution over time
SELECT 
    DATE(created_at) as date,
    COUNT(*) as records_per_day,
    COUNT(DISTINCT owner) as unique_owners,
    COUNT(DISTINCT source) as unique_sources,
    STRING_AGG(DISTINCT source, ', ') as sources_used
FROM claude_desktop_memory
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Summary statistics
SELECT 
    'Total Records' as metric,
    COUNT(*)::text as value
FROM claude_desktop_memory
UNION ALL
SELECT 
    'Unique Owners' as metric,
    COUNT(DISTINCT owner)::text as value
FROM claude_desktop_memory
UNION ALL
SELECT 
    'Unique Sources' as metric,
    COUNT(DISTINCT source)::text as value
FROM claude_desktop_memory
UNION ALL
SELECT 
    'Date Range' as metric,
    MIN(created_at)::date || ' to ' || MAX(created_at)::date as value
FROM claude_desktop_memory
UNION ALL
SELECT 
    'Avg Records Per Day' as metric,
    ROUND(COUNT(*) / NULLIF(DATE_PART('day', MAX(created_at) - MIN(created_at)), 0))::text as value
FROM claude_desktop_memory;