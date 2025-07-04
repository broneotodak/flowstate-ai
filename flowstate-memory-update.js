#!/usr/bin/env node

// Create comprehensive FlowState memory for todak-ai pgvector
const https = require('https');

const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

const flowstateMemory = {
  type: 'project_documentation',
  name: 'FlowState AI Dashboard - Complete Status',
  parent_name: 'flowstate-ai',
  text: `
# FlowState AI Dashboard - Comprehensive Project Status

## Project Overview
FlowState is a real-time activity tracking dashboard that aggregates data from multiple sources to provide a unified view of development activities. It's deployed at flowstate.neotodak.com via Netlify auto-deployment from GitHub.

## Current Architecture

### Data Sources
1. **Browser Extension** (FIXED)
   - Tracks browser activity across all tabs
   - Auto-detects GitHub projects
   - Logs to activity_log table every 5 minutes
   - Machine tracking implemented
   - Service key: Stored in Chrome extension settings

2. **Git Hooks** (WORKING)
   - Post-commit and post-push hooks
   - Logs to activity_log table
   - Tracks: commit messages, branches, authors
   - Installation: ~/.flowstate/install-to-repo.sh

3. **GitHub Webhooks** (WORKING)
   - Edge function handles GitHub events
   - Logs pushes, PRs, issues
   - Connected via GitHub repo settings

4. **System Monitor Daemon** (NEW)
   - Tracks active applications
   - Runs every 30 seconds
   - PID-based management

### Database Schema (Supabase)
Currently WORKING tables:
- activity_log: All activities from all sources
- current_context: Real-time project/task tracking
- user_machines: Registered devices
- user_tools: Available tools/integrations
- claude_desktop_memory: AI conversation memory

Currently BROKEN (referenced but missing):
- project_owners
- project_phases
- tasks
- project_status
- github_commits (separate from activity_log)
- time_tracking
- active_sessions

### Technical Stack
- Frontend: Vanilla JavaScript with Supabase Realtime
- Backend: Supabase (PostgreSQL with pgvector)
- Deployment: Netlify (auto-deploy from GitHub)
- Browser Extension: Chrome Manifest V3
- Edge Functions: Deno runtime

### Current Issues
1. Dashboard queries non-existent tables
2. No proper project/task management system
3. Time tracking not implemented
4. Project phases/status not tracked
5. No semantic search despite having embeddings

### Recent Changes (July 4, 2025)
1. Fixed browser extension Supabase URL
2. Added machine tracking to all components
3. Created universal logger for all tools
4. Implemented system monitor daemon
5. Enhanced git hooks with metadata

### Integration Points
1. **For AI Agents**: Use FlowStateLogger class
2. **For Editors**: VSCode extension ready (needs activation)
3. **For Terminal**: Shell aliases with tracking
4. **For Git**: Global hooks available

### Service Key Management
- Stored in ~/.flowstate/config
- Used by all components
- Type: service_role (bypasses RLS)

### Next Steps Required
1. Create missing database tables
2. Implement proper project management
3. Add time tracking functionality
4. Build semantic search interface
5. Create activity aggregation views
`,
  metadata: {
    project: 'flowstate-ai',
    last_updated: new Date().toISOString(),
    version: '2.0',
    status: 'partially_working',
    deployment_url: 'https://flowstate.neotodak.com',
    github_repo: 'https://github.com/broneotodak/flowstate-ai',
    key_files: [
      'index.html',
      'browser-extension/background.js',
      'flowstate-universal-logger.js',
      'setup-flowstate-tracking.sh'
    ]
  }
};

// Function to create embedding via edge function
async function createEmbedding(memory) {
  return new Promise((resolve, reject) => {
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
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log('✅ FlowState memory embedded successfully');
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(JSON.stringify(memory));
    req.end();
  });
}

// Log to activity_log
async function logMemoryUpdate() {
  const activity = {
    user_id: 'neo_todak',
    activity_type: 'project_documentation',
    activity_description: 'Updated FlowState project documentation in todak-ai memory',
    project_name: 'flowstate-ai',
    metadata: {
      action: 'memory_update',
      tool: 'claude-code',
      importance: 'high'
    }
  };
  
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/activity_log`);
    
    const req = https.request({
      hostname: url.hostname,
      path: url.pathname,
      method: 'POST',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      }
    }, (res) => {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        console.log('✅ Memory update logged to activity_log');
        resolve();
      } else {
        reject(new Error(`HTTP ${res.statusCode}`));
      }
    });
    
    req.on('error', reject);
    req.write(JSON.stringify(activity));
    req.end();
  });
}

// Execute
if (!SERVICE_KEY) {
  console.error('❌ Please set FLOWSTATE_SERVICE_KEY environment variable');
  process.exit(1);
}

console.log('📝 Creating FlowState memory embedding...');

Promise.all([
  createEmbedding(flowstateMemory),
  logMemoryUpdate()
]).then(() => {
  console.log('✅ FlowState project status saved to todak-ai memory!');
  console.log('   Other tools can now understand the project state');
}).catch(err => {
  console.error('❌ Failed to create memory:', err.message);
});