#!/usr/bin/env node

// This script logs Claude Code activities to FlowState
const https = require('https');
const os = require('os');

const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Please set FLOWSTATE_SERVICE_KEY environment variable');
  process.exit(1);
}

const machineId = `${os.hostname()}_claude_${Date.now()}`;

async function logActivity(activity) {
  const data = {
    user_id: 'neo_todak',
    activity_type: 'ai_conversation',
    activity_description: activity.description || 'Claude Code activity',
    project_name: activity.project || 'flowstate-ai-github',
    metadata: {
      tool: 'claude-code',
      machine_id: machineId,
      machine_name: os.hostname(),
      ...activity.metadata
    }
  };

  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/activity_log`);
    const options = {
      hostname: url.hostname,
      path: url.pathname,
      method: 'POST',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      }
    };

    const req = https.request(options, (res) => {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        resolve({ success: true });
      } else {
        reject(new Error(`HTTP ${res.statusCode}`));
      }
    });

    req.on('error', reject);
    req.write(JSON.stringify(data));
    req.end();
  });
}

// Log current Claude session
logActivity({
  description: 'Working on FlowState integration and browser extension fixes',
  project: 'flowstate-ai-github',
  metadata: {
    task: 'Fixing browser extension and setting up auto-tracking',
    phase: 'Development'
  }
}).then(() => {
  console.log('✅ Claude activity logged to FlowState');
}).catch(err => {
  console.error('❌ Failed to log activity:', err.message);
});

// Export for use in other scripts
module.exports = { logActivity, machineId };