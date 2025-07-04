#!/usr/bin/env node

// Manual activity logger - workaround for trigger issues
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function logActivity(activity) {
  const payload = {
    user_id: 'neo_todak',
    project_name: activity.project || 'Unknown',
    activity_type: activity.type || 'manual',
    activity_description: activity.description || 'Manual activity',
    metadata: activity.metadata || {},
    created_at: new Date().toISOString()
  };

  console.log('Logging activity:', payload);

  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/activity_log`);
    
    const options = {
      method: 'POST',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log('✅ Activity logged successfully');
          resolve(JSON.parse(data));
        } else {
          console.error(`❌ Failed to log activity: ${res.statusCode}`);
          console.error('Response:', data);
          reject(new Error(data));
        }
      });
    });

    req.on('error', reject);
    req.write(JSON.stringify(payload));
    req.end();
  });
}

// Test activities
async function testLogger() {
  const testActivities = [
    {
      project: 'flowstate-ai',
      type: 'development',
      description: 'Working on FlowState dashboard improvements with Claude',
      metadata: {
        source: 'Claude Desktop',
        machine: 'MacBook-Pro-3.local',
        tool: 'manual-logger'
      }
    },
    {
      project: 'cursor-project',
      type: 'development',
      description: 'Working on project in Cursor on Windows Office PC',
      metadata: {
        source: 'Cursor',
        machine: 'Office PC',
        tool: 'manual-logger'
      }
    }
  ];

  for (const activity of testActivities) {
    try {
      await logActivity(activity);
      await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1s between logs
    } catch (error) {
      console.error('Error:', error.message);
    }
  }
}

// Command line usage
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log('Running test activities...');
    testLogger();
  } else {
    const [project, type, ...descWords] = args;
    const description = descWords.join(' ');
    
    logActivity({
      project: project || 'Unknown',
      type: type || 'manual',
      description: description || 'Manual activity',
      metadata: {
        source: 'CLI',
        machine: require('os').hostname(),
        tool: 'manual-logger'
      }
    }).catch(console.error);
  }
}

module.exports = { logActivity };