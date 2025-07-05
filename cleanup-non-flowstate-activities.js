#!/usr/bin/env node

// Clean up non-FlowState activities from activity_log
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function cleanupActivities() {
  try {
    // Get recent activities that are NOT FlowState
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?order=created_at.desc&limit=100`, {
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
    
    // Find non-FlowState activities that were synced from memory
    const toDelete = activities.filter(activity => {
      // Check if it's from memory sync
      if (!activity.metadata || activity.metadata.source !== 'memory_sync') {
        return false;
      }
      
      // Check if it's NOT FlowState
      const projectName = activity.project_name?.toLowerCase() || '';
      return !projectName.includes('flowstate');
    });
    
    console.log(`Found ${toDelete.length} non-FlowState activities to clean up:\n`);
    
    toDelete.forEach(activity => {
      console.log(`- ${activity.project_name}: ${activity.activity_description?.substring(0, 50)}...`);
    });
    
    if (toDelete.length === 0) {
      console.log('No cleanup needed!');
      return;
    }
    
    // Ask for confirmation
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    readline.question('\nDelete these activities? (y/N): ', async (answer) => {
      if (answer.toLowerCase() === 'y') {
        for (const activity of toDelete) {
          try {
            const deleteResponse = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?id=eq.${activity.id}`, {
              method: 'DELETE',
              headers: {
                'apikey': SERVICE_KEY,
                'Authorization': `Bearer ${SERVICE_KEY}`,
                'Content-Type': 'application/json'
              }
            });
            
            if (deleteResponse.ok) {
              console.log(`✅ Deleted: ${activity.project_name}`);
            } else {
              console.log(`❌ Failed to delete: ${activity.project_name}`);
            }
          } catch (error) {
            console.error(`❌ Error deleting ${activity.id}:`, error.message);
          }
        }
        console.log('\n✅ Cleanup complete!');
      } else {
        console.log('Cancelled.');
      }
      readline.close();
    });

  } catch (error) {
    console.error('Error during cleanup:', error);
  }
}

cleanupActivities();