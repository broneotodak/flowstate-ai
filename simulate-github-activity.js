#!/usr/bin/env node

// Simulate GitHub browser activity for testing
const https = require('https');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function createGitHubActivity() {
  const activity = {
    user_id: 'neo_todak',
    project_name: 'FlowState AI',
    activity_type: 'browser_activity',
    activity_description: 'Viewing repository: flowstate-ai on GitHub',
    metadata: {
      source: 'browser_extension',
      tool: 'Chrome',
      machine: os.hostname(),
      url: 'https://github.com/username/flowstate-ai',
      browser: 'Chrome',
      confidence: 0.9
    }
  };

  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log`, {
      method: 'POST',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify(activity)
    });

    if (response.ok) {
      console.log('✅ Created GitHub browser activity');
      const data = await response.json();
      console.log(JSON.stringify(data[0], null, 2));
    } else {
      console.error('❌ Failed:', await response.text());
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

createGitHubActivity();