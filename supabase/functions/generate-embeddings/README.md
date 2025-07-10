# Generate Embeddings Edge Function

This Edge Function generates OpenAI embeddings for FlowState AI content.

## Quick Setup

### 1. Install Supabase CLI
```bash
brew install supabase/tap/supabase
```

### 2. Deploy the function
```bash
# From the flowstate-ai-github directory
supabase login
supabase link --project-ref YOUR_PROJECT_ID
supabase functions deploy generate-embeddings --no-verify-jwt
```

### 3. Set your OpenAI API key
```bash
supabase secrets set OPENAI_API_KEY=sk-your-openai-key-here
```

### 4. Create Database Webhook

Go to your Supabase Dashboard > Database > Webhooks and create webhooks for each table:

**For Projects table:**
- Name: `generate-embeddings-projects`
- Table: `projects`
- Events: Insert, Update
- URL: `https://YOUR_PROJECT_ID.supabase.co/functions/v1/generate-embeddings`
- Headers: 
  ```
  Content-Type: application/json
  Authorization: Bearer YOUR_SERVICE_ROLE_KEY
  ```
- Payload:
  ```json
  {
    "text": "{{name}} {{description}}",
    "table": "projects",
    "id": "{{id}}"
  }
  ```

Repeat for other tables (tasks, activities, project_phases) with appropriate text fields.

## Alternative: Manual Batch Generation

If you prefer to generate embeddings manually or in batch:

```bash
# Generate for a specific project
curl -X POST https://YOUR_PROJECT_ID.supabase.co/functions/v1/generate-embeddings \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Project Name and Description",
    "table": "projects",
    "id": "project-uuid-here"
  }'
```

## Testing Locally

```bash
supabase functions serve generate-embeddings --env-file .env.local

# Test with curl
curl -X POST http://localhost:54321/functions/v1/generate-embeddings \
  -H "Content-Type: application/json" \
  -d '{"text": "Test", "table": "projects", "id": "123"}'
```