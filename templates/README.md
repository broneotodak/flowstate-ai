# FlowState Memory Template

This template sets up a personal AI memory system that automatically tracks and organizes your coding activities, AI conversations, and digital work.

## What This Includes

- **PostgreSQL database** with pgvector extension for semantic search
- **Edge Function** for processing memories and generating embeddings
- **Automatic sync** between memory storage and FlowState activities
- **Smart project detection** from content patterns
- **Real-time dashboard** integration

## Quick Deploy to Supabase

1. **Create new Supabase project** at [supabase.com](https://supabase.com)
2. **Run the schema** - Copy and paste `flowstate-memory-schema.sql` in your SQL editor
3. **Deploy Edge Function** - Create a new function called `flowstate-memory` with the code from `flowstate-memory-function.ts`
4. **Set environment variables**:
   - `OPENAI_API_KEY` - Your OpenAI API key for embeddings
   - `SUPABASE_URL` - Your project URL (automatically set)
   - `SUPABASE_SERVICE_ROLE_KEY` - Your service role key (automatically set)

## Environment Variables Required

```bash
OPENAI_API_KEY=sk-proj-your-openai-key-here
```

## API Usage

### Save a Memory

```bash
curl -X POST "https://your-project.supabase.co/functions/v1/flowstate-memory" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "content": "Implemented semantic search using pgvector",
    "project": "FlowState",
    "tool": "claude_desktop",
    "memory_type": "feature",
    "importance": 8
  }'
```

### Search Memories

```sql
-- Search for similar memories
SELECT * FROM search_memories(
  query_embedding := (SELECT embedding FROM user_memories WHERE content ILIKE '%semantic search%' LIMIT 1),
  match_threshold := 0.7,
  match_count := 5
);
```

## Integration Examples

### Claude Desktop
Add this endpoint to your Claude Desktop memory sync settings:
```
https://your-project.supabase.co/functions/v1/flowstate-memory
```

### Cursor
Create a webhook in Cursor settings:
```json
{
  "url": "https://your-project.supabase.co/functions/v1/flowstate-memory",
  "events": ["file_save", "ai_conversation"]
}
```

### Manual Logging
```javascript
async function saveMemory(content, project = null, tool = 'manual') {
  const response = await fetch('https://your-project.supabase.co/functions/v1/flowstate-memory', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
    },
    body: JSON.stringify({ content, project, tool })
  });
  return response.json();
}
```

## Connecting to FlowState Dashboard

Once deployed, connect your memory system to FlowState:

1. Go to [flowstate.neotodak.com](https://flowstate.neotodak.com)
2. Add your Supabase URL in the settings
3. Your memories will automatically appear in the activity timeline

## Database Schema Overview

- **`user_memories`** - Core memory storage with semantic embeddings
- **`flowstate_activities`** - Processed activities for dashboard display  
- **`current_context`** - Track current project and task

## Cost Estimation

- **Supabase**: Free tier supports up to 500MB database
- **OpenAI Embeddings**: ~$0.0001 per 1k tokens (~$2-5/month for typical usage)

## Features

### 🧠 Semantic Search
Find memories by meaning, not just keywords:
```sql
-- Find memories about "debugging issues"
SELECT content, project_name, similarity 
FROM search_memories(
  (SELECT embedding FROM user_memories WHERE content ILIKE '%debugging%' LIMIT 1),
  'user', 0.6, 10
);
```

### 🎯 Smart Project Detection
Automatically categorizes your work:
- Code patterns → Project names
- File paths → Repository names  
- Content analysis → Work domains

### ⚡ Real-time Sync
Activities appear instantly in your FlowState dashboard:
- AI conversations
- Code commits  
- File edits
- Browser activities

### 🔒 Privacy First
- Your data stays in YOUR Supabase instance
- No third-party memory storage
- Full control over retention and access

## Troubleshooting

### Edge Function Not Working
1. Check OpenAI API key is set in environment variables
2. Verify function is deployed and active
3. Check function logs in Supabase dashboard

### No Embeddings Generated
1. Ensure OpenAI API key has sufficient credits
2. Check embedding model is available (text-embedding-3-small)
3. Verify content length is under token limits

### Dashboard Not Showing Data
1. Confirm Supabase URL is correct in FlowState settings
2. Check database permissions for anon key
3. Verify tables have data: `SELECT COUNT(*) FROM user_memories;`

## Support

- **Documentation**: [flowstate.neotodak.com/how-it-works](https://flowstate.neotodak.com/how-it-works)
- **Setup Guide**: [flowstate.neotodak.com/memory-setup](https://flowstate.neotodak.com/memory-setup)
- **GitHub**: Report issues and contribute improvements

---

**Ready to get started?** Deploy this template and transform your AI interactions into an intelligent, searchable memory system! 🚀
