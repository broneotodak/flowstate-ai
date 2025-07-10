#!/usr/bin/env node

// Clean up duplicate and incorrect machines
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function cleanupMachines() {
  console.log('🧹 Cleaning Up Machine List\n');
  
  try {
    // Machines to remove
    const toRemove = [
      {
        id: '545f343e-0492-45b4-b768-84367d36500c',
        name: 'MacBook Air',
        reason: 'Not an actual machine'
      },
      {
        id: '47cd0e39-5751-42a1-bd22-307f30f300e9', 
        name: 'Neo MacBook Pro (duplicate)',
        reason: 'Duplicate Mac entry'
      }
    ];
    
    console.log('Removing incorrect/duplicate machines:\n');
    
    for (const machine of toRemove) {
      console.log(`Removing: ${machine.name}`);
      console.log(`Reason: ${machine.reason}`);
      
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/user_machines?id=eq.${machine.id}`,
        {
          method: 'DELETE',
          headers: {
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          }
        }
      );
      
      if (response.ok) {
        console.log('✅ Removed successfully\n');
      } else {
        console.log('❌ Failed to remove:', await response.text(), '\n');
      }
    }
    
    // Update remaining machines with correct names
    console.log('Updating machine names to match your setup:\n');
    
    const updates = [
      {
        id: 'a774d834-f1ab-46c0-bdce-40163bff343b',
        name: 'Neo MacBook Pro',
        location: 'primary'
      },
      {
        id: '8048ec0f-6259-45a0-9c91-91584609d1cd',
        name: 'Windows Office PC',
        location: 'office'
      },
      {
        id: '99bfbb11-d455-48a6-9c32-5772883c4847',
        name: 'Windows Home PC',
        location: 'home'
      }
    ];
    
    for (const update of updates) {
      console.log(`Updating: ${update.name}`);
      
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/user_machines?id=eq.${update.id}`,
        {
          method: 'PATCH',
          headers: {
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            machine_name: update.name,
            location: update.location
          })
        }
      );
      
      if (response.ok) {
        console.log('✅ Updated\n');
      }
    }
    
    console.log('✅ Cleanup complete! You now have 3 machines:');
    console.log('1. Neo MacBook Pro (this machine)');
    console.log('2. Windows Home PC');
    console.log('3. Windows Office PC');
    
  } catch (error) {
    console.error('Error:', error);
  }
}

cleanupMachines();