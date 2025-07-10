#!/usr/bin/env node

// Automatic FlowState memory updater for todak-ai
// Runs periodically to keep project state in sync

const https = require('https');
const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

// Track last update time
const STATE_FILE = path.join(process.env.HOME, '.flowstate', 'last-memory-update.json');

async function getRecentActivities() {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/activity_log`);
    url.searchParams.append('select', '*');
    url.searchParams.append('order', 'created_at.desc');
    url.searchParams.append('limit', '10');
    
    https.get({
      hostname: url.hostname,
      path: url.pathname + url.search,
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}`));
        }
      });
    }).on('error', reject);
  });
}

async function getCurrentContext() {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/current_context`);
    url.searchParams.append('select', '*');
    url.searchParams.append('limit', '1');
    
    https.get({
      hostname: url.hostname,
      path: url.pathname + url.search,
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          const result = JSON.parse(data);
          resolve(result[0] || null);
        } else {
          reject(new Error(`HTTP ${res.statusCode}`));
        }
      });
    }).on('error', reject);
  });
}

async function updateMemory() {
  try {
    // Get current state
    const [activities, context] = await Promise.all([
      getRecentActivities(),
      getCurrentContext()
    ]);
    
    // Build memory text
    const memoryText = `
# FlowState Project Update - ${new Date().toISOString()}

## Current Context
${context ? `
- Project: ${context.project_name || 'None'}
- Task: ${context.current_task || 'None'}
- Phase: ${context.current_phase || 'None'}
- Last Updated: ${context.last_updated}
` : 'No active context'}

## Recent Activities (Last 10)
${activities.map(a => `
- **${a.activity_type}**: ${a.activity_description}
  - Project: ${a.project_name || 'Unknown'}
  - Time: ${a.created_at}
  - Source: ${a.metadata?.tool || a.metadata?.source || 'Unknown'}
`).join('')}

## Integration Status
- Browser Extension: ${context?.metadata?.detected_by === 'browser_extension' ? 'Active' : 'Unknown'}
- Git Hooks: ${activities.some(a => a.metadata?.source === 'git_hook') ? 'Active' : 'Unknown'}
- AI Tools: ${activities.some(a => a.activity_type === 'ai_conversation') ? 'Active' : 'Unknown'}
`;

    // Create embedding
    const memory = {
      type: 'project_update',
      name: `FlowState Update ${new Date().toISOString().split('T')[0]}`,
      parent_name: 'flowstate-ai',
      text: memoryText,
      metadata: {
        project: 'flowstate-ai',
        update_type: 'automatic',
        activities_count: activities.length,
        current_project: context?.project_name,
        timestamp: new Date().toISOString()
      }
    };

    // Send to embeddings function
    await new Promise((resolve, reject) => {
      const url = new URL(`${SUPABASE_URL}/functions/v1/generate-embeddings`);
      
      const req = https.request({
        hostname: url.hostname,
        path: url.pathname,
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        }
      }, (res) => {
        if (res.statusCode === 200) {
          console.log('✅ Memory updated successfully');
          resolve();
        } else {
          reject(new Error(`HTTP ${res.statusCode}`));
        }
      });
      
      req.on('error', reject);
      req.write(JSON.stringify(memory));
      req.end();
    });

    // Update state file
    fs.writeFileSync(STATE_FILE, JSON.stringify({
      lastUpdate: new Date().toISOString(),
      activitiesProcessed: activities.length
    }));

  } catch (error) {
    console.error('❌ Failed to update memory:', error.message);
  }
}

// Check if we should update (every hour)
function shouldUpdate() {
  if (!fs.existsSync(STATE_FILE)) return true;
  
  try {
    const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    const lastUpdate = new Date(state.lastUpdate);
    const hoursSinceUpdate = (Date.now() - lastUpdate.getTime()) / (1000 * 60 * 60);
    return hoursSinceUpdate >= 1;
  } catch {
    return true;
  }
}

// Main
if (!SERVICE_KEY) {
  console.error('❌ FLOWSTATE_SERVICE_KEY not set');
  process.exit(1);
}

if (process.argv[2] === '--force' || shouldUpdate()) {
  console.log('📝 Updating FlowState memory...');
  updateMemory();
} else {
  console.log('⏭️  Skipping update (too recent)');
}