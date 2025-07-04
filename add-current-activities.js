#!/usr/bin/env node

// Temporary script to show current activities
const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function addCurrentActivities() {
  const activities = [
    {
      id: 'manual-1',
      user_id: 'neo_todak',
      project_name: 'flowstate-ai',
      activity_type: 'development',
      activity_description: 'Fixed dashboard authentication by replacing anon key with service key',
      metadata: {
        source: 'Claude Desktop',
        machine: 'MacBook-Pro-3.local',
        tool: 'Claude Code'
      },
      created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString() // 30 minutes ago
    },
    {
      id: 'manual-1',
      user_id: 'neo_todak',
      project_name: 'flowstate-ai',
      activity_type: 'debugging',
      activity_description: 'Investigating activity_log trigger issue preventing new entries',
      metadata: {
        source: 'Claude Desktop',
        machine: 'MacBook-Pro-3.local',
        tool: 'Claude Code'
      },
      created_at: new Date(Date.now() - 15 * 60 * 1000).toISOString() // 15 minutes ago
    },
    {
      id: 'manual-1',
      user_id: 'neo_todak',
      project_name: 'cursor-project',
      activity_type: 'development',
      activity_description: 'Working on new feature implementation in Cursor',
      metadata: {
        source: 'Cursor',
        machine: 'Office PC',
        tool: 'Cursor AI'
      },
      created_at: new Date(Date.now() - 45 * 60 * 1000).toISOString() // 45 minutes ago
    },
    {
      id: 'manual-1',
      user_id: 'neo_todak',
      project_name: 'flowstate-ai',
      activity_type: 'solution',
      activity_description: 'Enhanced dashboard timestamps with relative time display (now, 5 minutes ago, etc)',
      metadata: {
        source: 'Claude Desktop',
        machine: 'MacBook-Pro-3.local',
        tool: 'Claude Code'
      },
      created_at: new Date(Date.now() - 10 * 60 * 1000).toISOString() // 10 minutes ago
    }
  ];

  console.log('Note: Direct inserts are failing due to database trigger issues.');
  console.log('These are the activities that SHOULD be logged:');
  console.log('');
  
  activities.forEach(act => {
    console.log(`- [${new Date(act.created_at).toLocaleTimeString()}] ${act.project_name}: ${act.activity_description}`);
  });
  
  console.log('\nTo fix this issue, we need to:');
  console.log('1. Identify and fix the database trigger causing "parent_name" ambiguity');
  console.log('2. Or create an edge function that bypasses the trigger');
  console.log('3. Or use the SQL function in create-log-activity-function.sql');
}

addCurrentActivities();