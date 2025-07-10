#!/usr/bin/env node

// Check for git commits in various tables
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function checkGitCommits() {
  console.log('🔍 Checking for Git Commits\n');
  
  // Check activities table
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activities?activity_type=eq.git_commit&order=created_at.desc&limit=5`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const commits = await response.json();
      console.log(`✅ Found ${commits.length} git commits in 'activities' table:`);
      commits.forEach(c => {
        console.log(`   - ${new Date(c.created_at).toLocaleString()}: ${c.activity_description}`);
      });
    } else {
      console.log('❌ Error checking activities table:', response.status);
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
  
  // Check activity_log table
  console.log('\n');
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?activity_type=eq.git_commit&order=created_at.desc&limit=5`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const commits = await response.json();
      console.log(`✅ Found ${commits.length} git commits in 'activity_log' table`);
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
  
  // Check flowstate_activities view
  console.log('\n');
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/flowstate_activities?activity_type=eq.git_commit&order=created_at.desc&limit=5`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const commits = await response.json();
      console.log(`✅ Found ${commits.length} git commits in 'flowstate_activities' view:`);
      commits.forEach(c => {
        console.log(`   - ${c.project_name}: ${c.activity_description}`);
      });
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
}

checkGitCommits();