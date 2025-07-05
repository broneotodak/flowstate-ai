# TODAK AI Supabase Database State
*Last Updated: July 4, 2025*

## Overview
The Todak AI Supabase instance hosts multiple projects. The main memory system uses `claude_desktop_memory` with pgvector for semantic search.

## Memory Storage Approach

### Primary Memory: claude_desktop_memory (pgvector)
- **Purpose**: Long-term memory storage for all AI tools
- **Issue**: Currently messy with incorrect source fields (everything shows as "claude_desktop")
- **Fields**: user_id, owner, source, memory_type, content, metadata, embedding
- **Total Entries**: ~1700+ memories

### FlowState-Specific Tables
These are the tables actually used by FlowState:

1. **activity_log** - Main activity tracking
   - All user activities across all tools
   - Types: git_commit, browser_activity, development, etc.
   - Connected to dashboard

2. **current_context** - Current working context
   - One record per user
   - Tracks current project/task

3. **user_machines** - Device tracking
   - All connected devices
   - Browser extensions create entries here

4. **context_embeddings** - FlowState pgvector storage
   - Used for activities and critical documentation
   - Alternative to claude_desktop_memory for FlowState

## Functions Created

### RPC Functions:
- `log_activity_simple()` - Direct activity logging without triggers

### Edge Functions:
- `generate-embeddings` - Creates pgvector embeddings
- `github-webhook` - Handles GitHub webhooks

## SQL Files Created (but not all executed)
Many SQL files were created during development:
- create_activities_table.sql (NOT USED - we use activity_log)
- fix-claude-memory-sources.sql (Should be run to fix memory)
- unified-flowstate-pgvector.sql (Unification approach)
- Various fix scripts

## Critical Memories Stored

### In context_embeddings:
1. **FlowState Database Truth** (July 4, 2025)
   - Documents correct table names
   - Prevents duplicate table creation

### In claude_desktop_memory:
1. **Universal Memory Storage Standard** 
   - How all AI tools should store memories
   - Fixes for source/owner fields

## Current Issues

1. **Memory Fragmentation**
   - claude_desktop_memory has wrong source fields
   - Multiple projects mixed together
   - No clear separation

2. **Table Confusion**
   - Many SQL files reference "activities" table (doesn't exist)
   - Should use "activity_log" instead

3. **Function Duplication Risk**
   - Multiple attempts to create similar functions
   - Need to check before creating new ones

## Recommendations

1. **Run Memory Fixes**
   ```sql
   -- Fix null owners
   UPDATE claude_desktop_memory SET owner = 'neo_todak' WHERE owner IS NULL;
   
   -- Fix sources based on content
   UPDATE claude_desktop_memory 
   SET source = CASE
     WHEN content ILIKE '%claude code%' THEN 'claude_code'
     WHEN content ILIKE '%cursor%' THEN 'cursor'
     ELSE source
   END
   WHERE source = 'claude_desktop';
   ```

2. **Use Proper Tables**
   - FlowState: Use context_embeddings for new memories
   - Other projects: Continue with claude_desktop_memory

3. **Before Creating Anything New**
   - Check this document
   - Check flowstate-database-truth.js
   - Query existing tables/functions first

## Active Components
- ✅ FlowState Dashboard (flowstate.neotodak.com)
- ✅ Browser Extension logging
- ✅ Git hooks (when configured)
- ✅ System monitor daemon
- ✅ Activity tracking to activity_log

## Database Access
```bash
# Set environment
source ~/.flowstate/config

# Check activities
curl -s "${FLOWSTATE_SUPABASE_URL}/rest/v1/activity_log?select=*&order=created_at.desc&limit=5" \
  -H "apikey: ${FLOWSTATE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${FLOWSTATE_SERVICE_KEY}" | jq '.'

# Check memories
curl -s "${FLOWSTATE_SUPABASE_URL}/rest/v1/claude_desktop_memory?select=*&order=created_at.desc&limit=5" \
  -H "apikey: ${FLOWSTATE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${FLOWSTATE_SERVICE_KEY}" | jq '.'
```

## Important Notes
- DO NOT create new tables without checking existing ones
- DO NOT assume table names - verify first
- All FlowState data goes to activity_log, NOT activities
- Consider using context_embeddings instead of claude_desktop_memory for new FlowState features