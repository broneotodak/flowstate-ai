#!/usr/bin/env node

// Check what's filtering records in flowstate_activities
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function checkViewFilter() {
  console.log('🔍 Checking flowstate_activities filtering\n');
  
  // Get a sample of records NOT in the view
  try {
    // First, get all activity IDs from the view
    const viewResponse = await fetch(`${SUPABASE_URL}/rest/v1/flowstate_activities?select=id`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`
      }
    });
    
    const viewRecords = await viewResponse.json();
    const viewIds = viewRecords.map(r => r.id);
    
    // Get recent records from activity_log
    const tableResponse = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?order=created_at.desc&limit=20`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`
      }
    });
    
    const tableRecords = await tableResponse.json();
    
    // Find records NOT in the view
    const missingRecords = tableRecords.filter(r => !viewIds.includes(r.id));
    
    console.log(`Found ${missingRecords.length} recent records NOT in flowstate_activities view:\n`);
    
    // Analyze why they're missing
    missingRecords.slice(0, 3).forEach(record => {
      console.log(`ID: ${record.id}`);
      console.log(`  user_id: ${record.user_id}`);
      console.log(`  project_name: ${record.project_name}`);
      console.log(`  activity_type: ${record.activity_type}`);
      console.log(`  has_embedding: ${record.has_embedding}`);
      console.log(`  created_at: ${record.created_at}`);
      console.log(`  metadata: ${JSON.stringify(record.metadata)}\n`);
    });
    
    // Check if it's filtering by user
    const uniqueUsers = [...new Set(tableRecords.map(r => r.user_id))];
    console.log('Unique users in activity_log:', uniqueUsers);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

checkViewFilter();