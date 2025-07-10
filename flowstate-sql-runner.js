#!/usr/bin/env node

// FlowState SQL Runner - Execute SQL via RPC
const https = require('https');
const fs = require('fs');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

// For future use when Supabase adds an RPC function for SQL execution
async function executeSqlViaRpc(sqlQuery) {
  console.log('Note: Direct SQL execution via REST API requires an RPC function.');
  console.log('Currently, SQL must be run via:');
  console.log('1. Supabase Dashboard SQL Editor');
  console.log('2. Direct PostgreSQL connection with psql');
  console.log('3. Creating specific RPC functions for each operation');
  
  return false;
}

// Alternative: Create specific functions for common operations
async function logActivitiesBatch(activities) {
  for (const activity of activities) {
    try {
      const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log`, {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify(activity)
      });
      
      if (response.ok) {
        console.log(`✅ Added: ${activity.activity_description}`);
      } else {
        console.error(`❌ Failed: ${await response.text()}`);
      }
    } catch (error) {
      console.error(`❌ Error: ${error.message}`);
    }
  }
}

// Check command line arguments
const args = process.argv.slice(2);
if (args.length === 0) {
  console.log('FlowState SQL Runner');
  console.log('Usage: node flowstate-sql-runner.js [sql-file]');
  console.log('\nNote: Direct SQL execution is not available via REST API.');
  console.log('Use Supabase Dashboard or create RPC functions.');
  process.exit(0);
}

const sqlFile = args[0];
if (fs.existsSync(sqlFile)) {
  const sql = fs.readFileSync(sqlFile, 'utf8');
  console.log('SQL to execute:');
  console.log('================');
  console.log(sql);
  console.log('================');
  console.log('\nPlease run this SQL in:');
  console.log('https://app.supabase.com/project/YOUR_PROJECT_ID/sql');
} else {
  console.error(`File not found: ${sqlFile}`);
}