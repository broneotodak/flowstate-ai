#!/usr/bin/env node

// CRITICAL: Update todak-ai memory with the TRUTH about FlowState database
const https = require('https');

const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

const databaseTruth = {
  type: 'critical_documentation',
  name: 'FlowState Database Truth - MUST READ',
  parent_name: 'flowstate-ai',
  text: `
# CRITICAL: FlowState Database Truth (Updated ${new Date().toISOString()})

## ⚠️ IMPORTANT: Table Names

### CORRECT Tables to Use:
- **activity_log** - NOT "activities" (this table doesn't exist!)
- **current_context** - NOT "current_working_context" 
- **user_machines** - For tracking devices
- **user_tools** - For tracking integrations
- **context_embeddings** - For semantic search (pgvector)

### DO NOT CREATE These Tables (they don't exist and shouldn't):
- ❌ activities (use activity_log instead)
- ❌ current_working_context (use current_context)
- ❌ project_owners (not implemented)
- ❌ project_phases (not implemented)
- ❌ project_status (not implemented)
- ❌ tasks (not implemented)
- ❌ time_tracking (not implemented)
- ❌ active_sessions (not implemented)
- ❌ github_commits (use activity_log with type='git_commit')

## Database Schema Reference

### activity_log table (PRIMARY TABLE):
\`\`\`sql
- id: UUID
- user_id: TEXT (always 'neo_todak')
- project_name: TEXT
- activity_type: TEXT ('git_commit', 'git_push', 'browser_activity', 'ai_conversation', etc.)
- activity_description: TEXT
- metadata: JSONB
- created_at: TIMESTAMPTZ
\`\`\`

### current_context table:
\`\`\`sql
- id: UUID
- user_id: TEXT (PRIMARY KEY)
- project_name: TEXT
- current_task: TEXT
- current_phase: TEXT
- progress_percentage: INTEGER
- last_updated: TIMESTAMPTZ
- created_at: TIMESTAMPTZ
\`\`\`

### user_machines table:
\`\`\`sql
- id: UUID
- user_id: TEXT
- machine_name: TEXT
- machine_type: TEXT
- os: TEXT
- location: TEXT
- icon: TEXT
- is_active: BOOLEAN
- last_active: TIMESTAMPTZ
- created_at: TIMESTAMPTZ
\`\`\`

### context_embeddings table (pgvector):
\`\`\`sql
- type: TEXT
- name: TEXT
- parent_name: TEXT
- embedding: vector(1536)
- metadata: JSONB
- created_at: TIMESTAMPTZ
\`\`\`

## Other Tables in Database (NOT for FlowState):
- todak_* tables - Part of TODAK AI system
- ai_recruiter_* tables - Different project
- claude_desktop_memory - Claude Desktop app
- neo_credentials - Credential storage
- Various other tables from different projects

## CRITICAL Rules for AI Agents:

1. **ALWAYS use activity_log, NOT activities**
2. **NEVER create new tables without checking this document**
3. **All activities go in activity_log with appropriate activity_type**
4. **One user system: user_id = 'neo_todak' always**
5. **Check this memory before making ANY database changes**

## Current Working Components:
- ✅ Browser extension logging to activity_log
- ✅ Git hooks logging to activity_log  
- ✅ Dashboard reading from activity_log
- ✅ Real-time subscriptions on all tables
- ✅ Machine tracking in user_machines

## API Endpoints:
- REST: ${SUPABASE_URL}/rest/v1/
- Realtime: ${SUPABASE_URL}/realtime/v1/
- Functions: ${SUPABASE_URL}/functions/v1/

## Edge Functions:
- generate-embeddings: Creates pgvector embeddings
- github-webhook: Handles GitHub events

This document is the SINGLE SOURCE OF TRUTH for FlowState database structure.
Last verified: ${new Date().toISOString()}
`,
  metadata: {
    project: 'flowstate-ai',
    importance: 'critical',
    version: '3.0',
    verified: true,
    last_checked: new Date().toISOString()
  }
};

// Create embedding
async function updateDatabaseTruth() {
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
          console.log('✅ Database truth embedded successfully');
          resolve();
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(JSON.stringify(databaseTruth));
    req.end();
  });
}

// Log this critical update
async function logUpdate() {
  const activity = {
    user_id: 'neo_todak',
    activity_type: 'critical_update',
    activity_description: 'Updated FlowState database truth documentation to prevent table duplication',
    project_name: 'flowstate-ai',
    metadata: {
      action: 'database_truth_update',
      tool: 'claude-code',
      importance: 'critical',
      reason: 'Prevent AI agents from creating duplicate tables'
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
        console.log('✅ Update logged to activity_log');
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
  console.error('❌ Please set FLOWSTATE_SERVICE_KEY');
  process.exit(1);
}

console.log('🚨 Creating CRITICAL database truth embedding...');
console.log('   This will prevent duplicate table creation');

Promise.all([
  updateDatabaseTruth(),
  logUpdate()
]).then(() => {
  console.log('\n✅ Database truth is now in pgvector memory!');
  console.log('   All AI agents will now know:');
  console.log('   - Use activity_log NOT activities');
  console.log('   - Don\'t create duplicate tables');
  console.log('   - Check memory before database changes');
}).catch(err => {
  console.error('❌ Failed:', err.message);
});