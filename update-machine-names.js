#!/usr/bin/env node

// Update machine names to be more meaningful
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'YOUR_SUPABASE_URL';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function updateMachineNames() {
  console.log('🖥️  Updating Machine Names\n');
  
  // First, let's see current machines
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/user_machines?order=last_active.desc`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    const machines = await response.json();
    console.log('Current machines:');
    machines.forEach(m => {
      console.log(`- ${m.machine_name} (${m.os}) - ID: ${m.id}`);
    });
    
    // Update suggestions
    const updates = [
      {
        current: 'MacBook-Pro-3.local',
        new: 'Neo MacBook Pro',
        icon: '💻'
      },
      {
        current: 'Office PC',
        new: 'Office Desktop',
        icon: '🏢'
      },
      {
        current: 'Home PC', 
        new: 'Home Desktop',
        icon: '🏠'
      },
      {
        current: 'MacBook',
        new: 'MacBook Air',
        icon: '🍎'
      }
    ];
    
    console.log('\nProposed updates:');
    for (const update of updates) {
      const machine = machines.find(m => m.machine_name === update.current);
      if (machine) {
        console.log(`\n${update.current} → ${update.new}`);
        
        const updateResponse = await fetch(`${SUPABASE_URL}/rest/v1/user_machines?id=eq.${machine.id}`, {
          method: 'PATCH',
          headers: {
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            machine_name: update.new,
            icon: update.icon
          })
        });
        
        if (updateResponse.ok) {
          console.log('✅ Updated successfully');
        } else {
          console.log('❌ Update failed:', await updateResponse.text());
        }
      }
    }
    
    // Also ensure the current machine (mac) is properly named
    const currentHostname = require('os').hostname();
    console.log('\nCurrent machine hostname:', currentHostname);
    
    if (currentHostname === 'mac') {
      // Find and update
      const macMachine = machines.find(m => m.machine_name === 'mac');
      if (macMachine) {
        console.log('\nUpdating current machine name from "mac" to "Neo MacBook Pro"');
        const updateResponse = await fetch(`${SUPABASE_URL}/rest/v1/user_machines?id=eq.${macMachine.id}`, {
          method: 'PATCH',
          headers: {
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            machine_name: 'Neo MacBook Pro',
            icon: '💻',
            location: 'primary'
          })
        });
        
        if (updateResponse.ok) {
          console.log('✅ Updated current machine');
        }
      }
    }
    
  } catch (error) {
    console.error('Error:', error);
  }
}

updateMachineNames();