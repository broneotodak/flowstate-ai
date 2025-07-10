#!/usr/bin/env node

// Test the exact queries the dashboard uses
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function testDashboardQueries() {
  console.log('🎯 Testing Dashboard Queries\n');
  
  // Today's Activities (from dashboard line 731)
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/flowstate_activities?created_at=gte.${today.toISOString()}&select=*&limit=0`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );
    
    const count = response.headers.get('content-range')?.split('/')[1] || '0';
    console.log(`📊 Today's Activities (flowstate_activities): ${count}`);
    
    // Try with activity_log
    const response2 = await fetch(
      `${SUPABASE_URL}/rest/v1/activity_log?created_at=gte.${today.toISOString()}&select=*&limit=0`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );
    
    const count2 = response2.headers.get('content-range')?.split('/')[1] || '0';
    console.log(`📊 Today's Activities (activity_log): ${count2}`);
    
  } catch (error) {
    console.error('Error:', error);
  }
  
  // Total Commits (from dashboard line 753)
  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/flowstate_activities?activity_type=eq.git_commit&select=*&limit=0`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );
    
    const count = response.headers.get('content-range')?.split('/')[1] || '0';
    console.log(`\n💾 Total Commits (flowstate_activities): ${count}`);
    
    // Try with activity_log
    const response2 = await fetch(
      `${SUPABASE_URL}/rest/v1/activity_log?activity_type=eq.git_commit&select=*&limit=0`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );
    
    const count2 = response2.headers.get('content-range')?.split('/')[1] || '0';
    console.log(`💾 Total Commits (activity_log): ${count2}`);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

testDashboardQueries();