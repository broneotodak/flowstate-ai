# FlowState AI - Edge Function Setup Guide

## Prerequisites
1. Supabase CLI installed (`brew install supabase/tap/supabase`)
2. OpenAI API key
3. Supabase project credentials

## Setup Steps

### 1. Login to Supabase CLI
```bash
supabase login
```

### 2. Link your project
```bash
cd /Users/broneotodak/Projects/flowstate-ai-github
supabase link --project-ref uzamamymfzhelvkwpvgt
```

### 3. Set up environment variables
Create `.env.local` file:
```bash
OPENAI_API_KEY=your_openai_api_key_here
```

### 4. Deploy the Edge Function
```bash
supabase functions deploy generate-embeddings --no-verify-jwt
```

### 5. Set the OpenAI API key secret
```bash
supabase secrets set OPENAI_API_KEY=your_openai_api_key_here
```

## Testing the Function

### Test locally:
```bash
supabase functions serve generate-embeddings --env-file .env.local
```

### Test with curl:
```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/generate-embeddings' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"text":"Test embedding generation","table":"projects","id":"test-123"}'
```

## Update Database Triggers

After deploying, update your database triggers to call this Edge Function:

```sql
-- Update the embedding trigger to call Edge Function
CREATE OR REPLACE FUNCTION call_edge_function_for_embedding()
RETURNS TRIGGER AS $$
DECLARE
    content_text TEXT;
    edge_function_url TEXT;
BEGIN
    -- Get the Edge Function URL
    edge_function_url := 'https://uzamamymfzhelvkwpvgt.supabase.co/functions/v1/generate-embeddings';
    
    -- Extract content based on table
    IF TG_TABLE_NAME = 'projects' THEN
        content_text := COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.description, '');
    ELSIF TG_TABLE_NAME = 'project_phases' THEN
        content_text := COALESCE(NEW.name, '') || ' Status: ' || COALESCE(NEW.status, '');
    ELSIF TG_TABLE_NAME = 'tasks' THEN
        content_text := COALESCE(NEW.title, '') || ' ' || COALESCE(NEW.description, '');
    ELSIF TG_TABLE_NAME = 'activities' THEN
        content_text := COALESCE(NEW.description, '') || ' Type: ' || COALESCE(NEW.activity_type, '');
    END IF;
    
    -- Call Edge Function asynchronously
    PERFORM net.http_post(
        url := edge_function_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key')
        ),
        body := jsonb_build_object(
            'text', content_text,
            'table', TG_TABLE_NAME,
            'id', NEW.id::text
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Enable pg_net extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_net;
```

## Batch Generation for Existing Data

To generate embeddings for all existing data:

```sql
CREATE OR REPLACE FUNCTION generate_all_embeddings_via_edge_function()
RETURNS void AS $$
DECLARE
    rec RECORD;
    edge_function_url TEXT := 'https://uzamamymfzhelvkwpvgt.supabase.co/functions/v1/generate-embeddings';
BEGIN
    -- Generate for projects
    FOR rec IN SELECT id, name, description FROM projects LOOP
        PERFORM net.http_post(
            url := edge_function_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key')
            ),
            body := jsonb_build_object(
                'text', COALESCE(rec.name, '') || ' ' || COALESCE(rec.description, ''),
                'table', 'projects',
                'id', rec.id::text
            )
        );
    END LOOP;
    
    -- Repeat for other tables...
END;
$$ LANGUAGE plpgsql;
```

## Monitoring

Check Edge Function logs:
```bash
supabase functions logs generate-embeddings
```

## Cost Considerations

- OpenAI text-embedding-3-small: ~$0.02 per 1M tokens
- Approximately 1-2 tokens per word
- Monitor usage in OpenAI dashboard

## Troubleshooting

1. **Function not deploying**: Make sure you're logged in and linked to the correct project
2. **401 Unauthorized**: Check your API keys and function permissions
3. **Network errors**: Ensure pg_net extension is enabled in your database
4. **Embeddings not generating**: Check function logs for errors