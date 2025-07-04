# Browser Extension Service Key Debugging Guide

## Issue Summary
The browser extension is not successfully logging activities to Supabase. Based on the code analysis, here are the potential issues and solutions:

## Key Findings

### 1. Service Key Validation
The extension checks for the service key in `background.js` (lines 63-67) but only logs a message if it's missing. There's no validation that the key is correct.

### 2. API Call Error Handling
The `logCurrentActivity` function (lines 231-295) has error handling that only logs to console. Errors are not surfaced to the user.

### 3. Row Level Security (RLS)
The SQL files show that RLS was initially enabled but then disabled in the fix script. This could cause permission issues.

### 4. Activity Logging Conditions
Activities are only logged if:
- A project is detected (`currentContext.project` exists)
- Service key is configured
- Extension is enabled
- 5-minute interval has passed (or manual trigger)

## Debugging Steps

### Step 1: Verify Extension Installation
1. Open Chrome and go to `chrome://extensions/`
2. Find "FlowState Context Tracker"
3. Ensure it's enabled
4. Click "Service Worker" to view console logs

### Step 2: Check Service Key Configuration
1. Click the extension icon
2. Verify the service key is entered
3. Ensure "Enable Tracking" is checked
4. Click "Save Settings"

### Step 3: Test API Connection
1. Open Chrome DevTools (F12) on any webpage
2. Go to Console tab
3. Copy and paste the contents of `test-api.js`
4. Run: `testAPIConnection('your-service-key-here')`

### Step 4: Check Service Worker Logs
1. In `chrome://extensions/`, click "Service Worker" for the extension
2. Look for:
   - "FlowState Context Tracker installed"
   - "Service key not configured" (if missing)
   - "Error logging activity:" messages
   - "Activity logged successfully" messages

### Step 5: Verify Context Detection
1. Navigate to a GitHub repository with "flowstate" in the name
2. Click the extension icon
3. Check if a project is detected (should show "FlowState" with confidence %)
4. Click "Log Activity Now" to force immediate logging

### Step 6: Check Supabase Permissions
Run this SQL in Supabase SQL Editor:
```sql
-- Check if activities table exists
SELECT table_name, is_insertable_into 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'activities';

-- Check RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'activities';

-- Test insert permission
INSERT INTO activities (user_id, activity_type, description, project_name) 
VALUES ('neo_todak', 'test', 'Permission test', 'Test');

-- Check recent activities
SELECT * FROM activities 
WHERE user_id = 'neo_todak' 
ORDER BY created_at DESC 
LIMIT 10;
```

## Common Issues and Solutions

### Issue 1: Invalid Service Key
**Symptoms**: 401 or 403 errors in console
**Solution**: 
- Verify you're using the service role key (starts with `eyJ...`)
- Not the anon key
- Check in Supabase Dashboard > Settings > API

### Issue 2: No Project Detection
**Symptoms**: Extension shows "No active project detected"
**Solution**:
- Navigate to a GitHub repo or Claude.ai conversation
- Ensure the URL/title contains project keywords
- Click "Refresh Context" button

### Issue 3: RLS Blocking Inserts
**Symptoms**: 403 errors even with valid service key
**Solution**:
- Service role key should bypass RLS
- If not working, temporarily disable RLS:
```sql
ALTER TABLE activities DISABLE ROW LEVEL SECURITY;
ALTER TABLE current_context DISABLE ROW LEVEL SECURITY;
```

### Issue 4: Network/CORS Issues
**Symptoms**: Network errors in console
**Solution**:
- Check if `https://*.supabase.co/*` is in manifest permissions
- Verify Supabase URL is correct
- Check for any firewall/proxy blocking

## Testing Checklist

- [ ] Extension is installed and enabled
- [ ] Service key is saved in extension settings
- [ ] Extension icon shows badge (e.g., "FL" for FlowState) when on relevant pages
- [ ] "Log Activity Now" button works without errors
- [ ] Activities appear in Supabase database
- [ ] Console shows "Activity logged successfully"

## Additional Debugging

### Enable Verbose Logging
Add to the beginning of `background.js`:
```javascript
const DEBUG = true;
const log = (...args) => DEBUG && console.log('[FlowState]', ...args);
```

Then replace all `console.log` with `log` for better filtering.

### Check Chrome Storage
In extension Service Worker console:
```javascript
chrome.storage.local.get(null, (data) => console.log('All storage:', data));
```

### Force Activity Log
In extension Service Worker console:
```javascript
logCurrentActivity();
```

## Next Steps

1. Run through the debugging steps above
2. Check which step fails
3. Apply the corresponding solution
4. If issues persist, check:
   - Supabase service health
   - Chrome extension permissions
   - Any ad blockers or security extensions that might interfere