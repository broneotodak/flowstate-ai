#!/usr/bin/env node

// Register or update current machine
const os = require('os');
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function registerCurrentMachine() {
  const hostname = os.hostname();
  const platform = os.platform();
  const osType = platform === 'darwin' ? 'macOS' : platform === 'win32' ? 'Windows' : 'Linux';
  
  console.log('💻 Registering Current Machine\n');
  console.log('Hostname:', hostname);
  console.log('Platform:', osType);
  
  const machineData = {
    user_id: 'neo_todak',
    machine_name: hostname === 'mac' ? 'Neo MacBook Pro (Primary)' : hostname,
    os: osType.toLowerCase(),
    machine_type: 'laptop',
    location: 'primary',
    icon: '💻',
    is_active: true,
    last_active: new Date().toISOString()
  };
  
  try {
    // Check if machine exists
    const checkResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/user_machines?machine_name=eq.${hostname}`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    const existing = await checkResponse.json();
    
    if (existing.length > 0) {
      // Update existing
      console.log('\nUpdating existing machine registration...');
      const updateResponse = await fetch(
        `${SUPABASE_URL}/rest/v1/user_machines?id=eq.${existing[0].id}`,
        {
          method: 'PATCH',
          headers: {
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(machineData)
        }
      );
      
      if (updateResponse.ok) {
        console.log('✅ Machine updated successfully');
      }
    } else {
      // Create new
      console.log('\nRegistering new machine...');
      const createResponse = await fetch(
        `${SUPABASE_URL}/rest/v1/user_machines`,
        {
          method: 'POST',
          headers: {
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(machineData)
        }
      );
      
      if (createResponse.ok) {
        console.log('✅ Machine registered successfully');
      }
    }
    
  } catch (error) {
    console.error('Error:', error);
  }
}

registerCurrentMachine();