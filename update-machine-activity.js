#!/usr/bin/env node

// Update machine last active time when logging activities
const https = require('https');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function updateMachineActivity(machineName) {
  const url = new URL(`${SUPABASE_URL}/rest/v1/user_machines?machine_name=eq.${encodeURIComponent(machineName || os.hostname())}`);
  const data = JSON.stringify({
    last_active: new Date().toISOString(),
    is_active: true
  });
  
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'PATCH',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    }, (res) => {
      if (res.statusCode < 300) {
        console.log(`✅ Updated machine activity: ${machineName || os.hostname()}`);
        resolve();
      } else {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => reject(new Error(`Failed: ${body}`)));
      }
    });
    
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

// Also ensure machine exists
async function ensureMachineExists(machineName) {
  const name = machineName || os.hostname();
  
  // First check if exists
  const checkUrl = new URL(`${SUPABASE_URL}/rest/v1/user_machines?machine_name=eq.${encodeURIComponent(name)}&select=id`);
  
  const exists = await new Promise((resolve) => {
    https.get(checkUrl, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const results = JSON.parse(data);
        resolve(results.length > 0);
      });
    }).on('error', () => resolve(false));
  });
  
  if (!exists) {
    // Create machine
    const createUrl = new URL(`${SUPABASE_URL}/rest/v1/user_machines`);
    const machineData = {
      user_id: 'neo_todak',
      machine_name: name,
      machine_type: name.includes('MacBook') ? 'laptop' : 'desktop',
      os: process.platform === 'darwin' ? 'macOS' : process.platform === 'win32' ? 'Windows' : 'Linux',
      location: name.includes('Office') ? 'office' : 'home',
      icon: name.includes('MacBook') ? '💻' : '🖥️',
      is_active: true,
      last_active: new Date().toISOString()
    };
    
    await new Promise((resolve, reject) => {
      const data = JSON.stringify(machineData);
      const req = https.request(createUrl, {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Content-Length': data.length
        }
      }, (res) => {
        if (res.statusCode < 300) {
          console.log(`✅ Created machine: ${name}`);
          resolve();
        } else {
          reject(new Error('Failed to create machine'));
        }
      });
      
      req.on('error', reject);
      req.write(data);
      req.end();
    });
  }
}

// Run if called directly
if (require.main === module) {
  if (!SERVICE_KEY) {
    console.error('❌ FLOWSTATE_SERVICE_KEY not found');
    process.exit(1);
  }
  
  const machineName = process.argv[2] || os.hostname();
  
  ensureMachineExists(machineName)
    .then(() => updateMachineActivity(machineName))
    .catch(console.error);
}

module.exports = { updateMachineActivity, ensureMachineExists };