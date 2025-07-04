#!/usr/bin/env node

const https = require('https');
const fs = require('fs');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function executeSql(query) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/rpc/query`);
    
    const options = {
      method: 'POST',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(JSON.stringify({ query }));
    req.end();
  });
}

// First, let's try a simpler approach - check if we can create the function
async function createInsertFunction() {
  const createFunctionSql = `
CREATE OR REPLACE FUNCTION insert_activity_log(
    p_user_id TEXT,
    p_project_name TEXT,
    p_activity_type TEXT,
    p_activity_description TEXT,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS SETOF activity_log
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO activity_log (
        user_id,
        project_name,
        activity_type,
        activity_description,
        metadata
    ) VALUES (
        p_user_id,
        p_project_name,
        p_activity_type,
        p_activity_description,
        p_metadata
    )
    RETURNING *;
END;
$$;`;

  // We can't execute arbitrary SQL via REST API, so let's try the RPC approach
  console.log('Note: Direct SQL execution via REST API is limited.');
  console.log('Let\'s try using the function if it exists...');
  
  return testInsertFunction();
}

async function testInsertFunction() {
  const url = `${SUPABASE_URL}/rest/v1/rpc/insert_activity_log`;
  const testData = {
    p_user_id: 'neo_todak',
    p_project_name: 'flowstate-ai',
    p_activity_type: 'test',
    p_activity_description: 'Testing insert function via RPC',
    p_metadata: {
      source: 'execute-sql-via-api.js',
      machine: require('os').hostname(),
      timestamp: new Date().toISOString()
    }
  };

  console.log('Testing RPC function insert_activity_log...');
  console.log('URL:', url);
  console.log('Data:', JSON.stringify(testData, null, 2));

  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    
    const options = {
      hostname: parsedUrl.hostname,
      path: parsedUrl.pathname,
      method: 'POST',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`Response Status: ${res.statusCode}`);
        console.log('Response:', data);
        
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log('✅ Success! Activity logged via RPC function');
          resolve(JSON.parse(data));
        } else {
          console.log('❌ Failed to execute RPC function');
          if (res.statusCode === 404) {
            console.log('\nThe function doesn\'t exist yet. You need to create it first.');
            console.log('Please run the SQL in sql/fix-activity-log-trigger.sql via Supabase Dashboard');
          }
          reject(new Error(data));
        }
      });
    });

    req.on('error', (e) => {
      console.error('Request error:', e);
      reject(e);
    });

    req.write(JSON.stringify(testData));
    req.end();
  });
}

// Run the test
if (require.main === module) {
  console.log('FlowState Activity Log Fix Attempt\n');
  
  testInsertFunction()
    .then(result => {
      console.log('\nResult:', result);
      console.log('\nNext step: Check your dashboard to see if the activity appears!');
    })
    .catch(error => {
      console.error('\nError:', error.message);
      console.log('\nTo fix this issue:');
      console.log('1. Go to https://app.supabase.com/project/uzamamymfzhelvkwpvgt/sql');
      console.log('2. Run the SQL from sql/fix-activity-log-trigger.sql');
      console.log('3. Then run this script again');
    });
}