#!/usr/bin/env node

// Check and clean up machine list
const os = require('os');
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function checkMachines() {
  console.log('🔍 Checking All Registered Machines\n');
  
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/user_machines?order=last_active.desc`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    const machines = await response.json();
    console.log(`Found ${machines.length} machines:\n`);
    
    machines.forEach((m, index) => {
      console.log(`${index + 1}. ${m.machine_name}`);
      console.log(`   ID: ${m.id}`);
      console.log(`   OS: ${m.os}`);
      console.log(`   Type: ${m.machine_type}`);
      console.log(`   Location: ${m.location}`);
      console.log(`   Active: ${m.is_active}`);
      console.log(`   Last Active: ${m.last_active}`);
      console.log(`   Created: ${m.created_at}\n`);
    });
    
    // Your actual machines
    console.log('Your ACTUAL machines should be:');
    console.log('1. This MacBook (current)');
    console.log('2. Windows Home PC');
    console.log('3. Windows Office PC');
    console.log('\nFuture machines:');
    console.log('4. Windows Bandung Office PC');
    console.log('5. Windows Bandung Home Laptop');
    
    // Check for duplicates or incorrect entries
    const macbooks = machines.filter(m => m.os === 'macos' || m.os === 'macOS');
    console.log(`\n⚠️  Found ${macbooks.length} Mac machines - should only be 1`);
    
    const currentHostname = os.hostname();
    console.log(`\nCurrent machine hostname: ${currentHostname}`);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

checkMachines();