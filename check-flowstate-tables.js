#!/usr/bin/env node

// Check FlowState tables and views
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function checkTables() {
  console.log('🔍 Checking FlowState Database Structure\n');
  
  // Check flowstate_activities
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/flowstate_activities?limit=1`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const data = await response.json();
      console.log('✅ flowstate_activities exists');
      if (data.length > 0) {
        console.log('   Sample columns:', Object.keys(data[0]).join(', '));
      }
    } else {
      console.log('❌ flowstate_activities not found or error:', response.status);
    }
  } catch (error) {
    console.log('❌ Error checking flowstate_activities:', error.message);
  }
  
  // Check activity_log
  console.log('\n');
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?limit=1`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const data = await response.json();
      console.log('✅ activity_log exists');
      if (data.length > 0) {
        console.log('   Sample columns:', Object.keys(data[0]).join(', '));
      }
    }
  } catch (error) {
    console.log('❌ Error checking activity_log:', error.message);
  }
  
  // Check for git commits
  console.log('\n📊 Checking for git commits:');
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?activity_type=eq.git_commit&limit=5`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const commits = await response.json();
      console.log(`Found ${commits.length} git commits in activity_log`);
    }
  } catch (error) {
    console.log('Error checking commits:', error.message);
  }
  
  // Check for today's activities
  console.log('\n📊 Checking today\'s activities:');
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?created_at=gte.${today.toISOString()}&limit=10`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const activities = await response.json();
      console.log(`Found ${activities.length} activities today in activity_log`);
      activities.forEach(a => {
        console.log(`  - ${a.activity_type}: ${a.activity_description?.substring(0, 50)}...`);
      });
    }
  } catch (error) {
    console.log('Error checking today\'s activities:', error.message);
  }
}

checkTables();