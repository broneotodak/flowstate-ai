#!/usr/bin/env node

// Check activity_log structure
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function checkActivityLogStructure() {
  try {
    // Get one record to see structure
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?limit=1`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const activities = await response.json();
    
    console.log('=== Activity Log Structure ===\n');
    
    if (activities.length > 0) {
      console.log('Columns found:');
      console.log(Object.keys(activities[0]).join(', '));
      console.log('\nExample record:');
      console.log(JSON.stringify(activities[0], null, 2));
    } else {
      console.log('No activities found, creating test activity to check structure...');
      
      // Try to create one to see what fields are accepted
      const testActivity = {
        user_id: 1,
        machine_id: 2,
        project_name: 'Test Project',
        activity_type: 'development',
        activity_description: 'Test activity',
        timestamp: new Date().toISOString()
      };
      
      const createResponse = await fetch(`${SUPABASE_URL}/rest/v1/activity_log`, {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify(testActivity)
      });
      
      if (createResponse.ok) {
        const created = await createResponse.json();
        console.log('Created test activity:');
        console.log(JSON.stringify(created, null, 2));
      } else {
        console.log('Error creating test activity:', await createResponse.text());
      }
    }

  } catch (error) {
    console.error('Error checking activity log structure:', error);
  }
}

checkActivityLogStructure();