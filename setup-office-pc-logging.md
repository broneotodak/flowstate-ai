# Setup FlowState on Office PC (Windows)

## Quick Setup for Cursor Integration

### 1. Create FlowState Config
Create file: `C:\Users\[YourUsername]\.flowstate\config.bat`
```batch
@echo off
set FLOWSTATE_SUPABASE_URL=YOUR_SUPABASE_URL_HERE
set FLOWSTATE_SERVICE_KEY=YOUR_SUPABASE_KEY_HERE
```

### 2. Install Node.js (if not already installed)
Download from: https://nodejs.org/

### 3. Create Logger Script
Save this as `C:\Users\[YourUsername]\.flowstate\log-activity.js`:
```javascript
const https = require('https');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL;
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

function logActivity(project, type, description) {
  const payload = {
    user_id: 'neo_todak',
    project_name: project || 'kenal-admin',
    activity_type: type || 'development',
    activity_description: description,
    metadata: {
      source: 'Cursor',
      machine: 'Office PC',
      tool: 'Cursor AI',
      hostname: os.hostname()
    }
  };

  const data = JSON.stringify(payload);
  const url = new URL(`${SUPABASE_URL}/rest/v1/activity_log`);
  
  const options = {
    hostname: url.hostname,
    path: url.pathname,
    method: 'POST',
    headers: {
      'apikey': SERVICE_KEY,
      'Authorization': `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  const req = https.request(options, (res) => {
    if (res.statusCode < 300) {
      console.log('Activity logged!');
    }
  });

  req.write(data);
  req.end();
}

// Get arguments
const args = process.argv.slice(2);
if (args.length > 0) {
  logActivity(args[0], args[1], args.slice(2).join(' '));
} else {
  console.log('Usage: node log-activity.js [project] [type] [description]');
}
```

### 4. Create Batch Script for Easy Logging
Save as `C:\Users\[YourUsername]\.flowstate\flowlog.bat`:
```batch
@echo off
call C:\Users\[YourUsername]\.flowstate\config.bat
node C:\Users\[YourUsername]\.flowstate\log-activity.js %*
```

### 5. Add to PATH (Optional)
Add `C:\Users\[YourUsername]\.flowstate` to your system PATH so you can run `flowlog` from anywhere.

### 6. Usage in Cursor Terminal
```batch
flowlog kenal-admin development "Implementing new admin features"
flowlog kenal-admin debugging "Fixing user authentication"
flowlog kenal-admin git_commit "Added role management system"
```

### 7. Cursor Extension (Future)
We can create a Cursor/VSCode extension that automatically logs:
- File saves
- Git commits
- Terminal commands
- Debug sessions

Would you like me to create the extension?