# How to Execute the SQL Fix

## Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project: https://app.supabase.com/project/uzamamymfzhelvkwpvgt
2. Navigate to SQL Editor (left sidebar)
3. Copy and paste the contents of `sql/fix-activity-log-trigger.sql`
4. Run the query
5. Share the output with me so I can see what triggers exist

## Option 2: Using psql with connection string
If you have the full database connection string:
```bash
psql "postgresql://postgres:[password]@db.uzamamymfzhelvkwpvgt.supabase.co:5432/postgres" -f sql/fix-activity-log-trigger.sql
```

## Option 3: Using Supabase CLI (requires project linking)
```bash
# First, you'd need to login and link the project
supabase login
supabase link --project-ref uzamamymfzhelvkwpvgt

# Then execute SQL
supabase db execute -f sql/fix-activity-log-trigger.sql
```

## Option 4: Using curl with REST API
I can create a script that executes SQL via the REST API if needed.

## Quick Test
For now, let's try a quick test using the service key to execute our function directly:
```bash
source ~/.flowstate/config
curl -X POST "${FLOWSTATE_SUPABASE_URL}/rest/v1/rpc/insert_activity_log" \
  -H "apikey: ${FLOWSTATE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${FLOWSTATE_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "p_user_id": "neo_todak",
    "p_project_name": "flowstate-ai",
    "p_activity_type": "test",
    "p_activity_description": "Testing RPC function",
    "p_metadata": {"source": "curl test"}
  }'
```

Please let me know which option works best for you!