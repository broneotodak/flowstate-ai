#!/usr/bin/env node

// Debug flowstate_activities view
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function debugView() {
  console.log('🔍 Debugging flowstate_activities view\n');
  
  // Get total counts
  try {
    const [viewResponse, tableResponse] = await Promise.all([
      fetch(`${SUPABASE_URL}/rest/v1/flowstate_activities?select=*&limit=0`, {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'count=exact'
        }
      }),
      fetch(`${SUPABASE_URL}/rest/v1/activity_log?select=*&limit=0`, {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'count=exact'
        }
      })
    ]);
    
    const viewCount = viewResponse.headers.get('content-range')?.split('/')[1] || '0';
    const tableCount = tableResponse.headers.get('content-range')?.split('/')[1] || '0';
    
    console.log(`📊 Record counts:`);
    console.log(`   activity_log table: ${tableCount} records`);
    console.log(`   flowstate_activities view: ${viewCount} records`);
    console.log(`   Difference: ${parseInt(tableCount) - parseInt(viewCount)} records missing from view`);
    
  } catch (error) {
    console.error('Error getting counts:', error);
  }
  
  // Check view definition by looking at sample data
  console.log('\n📋 Checking view columns:');
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
      if (data.length > 0) {
        console.log('   View columns:', Object.keys(data[0]).join(', '));
        
        // Check for extra columns not in activity_log
        const activityLogResponse = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?limit=1`, {
          headers: {
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          }
        });
        
        const activityLogData = await activityLogResponse.json();
        const viewColumns = Object.keys(data[0]);
        const tableColumns = Object.keys(activityLogData[0]);
        
        const extraColumns = viewColumns.filter(col => !tableColumns.includes(col));
        if (extraColumns.length > 0) {
          console.log('   Extra columns in view:', extraColumns.join(', '));
        }
      }
    }
  } catch (error) {
    console.error('Error checking columns:', error);
  }
  
  // Check recent git commit
  console.log('\n🔍 Checking recent git commit:');
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?activity_type=eq.git_commit&order=created_at.desc&limit=1`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const commits = await response.json();
      if (commits.length > 0) {
        console.log('   Latest git commit in activity_log:');
        console.log('   ', JSON.stringify(commits[0], null, 2));
      }
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

debugView();