#!/usr/bin/env node

// Search for Kenal Admin project memories in pgvector database
const https = require('https');

const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('❌ Please set FLOWSTATE_SERVICE_KEY environment variable');
  process.exit(1);
}

// Function to make Supabase REST API calls
async function supabaseQuery(table, query = '') {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/${table}${query}`);
    
    const req = https.request({
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: 'GET',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error('Failed to parse response'));
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.end();
  });
}

async function searchKenalMemories() {
  console.log('🔍 Searching for Kenal Admin memories...\n');

  try {
    // 1. Search context_embeddings for Kenal-related entries
    console.log('1. Searching context_embeddings table for "kenal" entries...');
    const contextResults = await supabaseQuery('context_embeddings', 
      '?or=(name.ilike.*kenal*,parent_name.ilike.*kenal*,text.ilike.*kenal*)&order=created_at.desc');
    
    if (contextResults.length > 0) {
      console.log(`   Found ${contextResults.length} entries:`);
      contextResults.forEach(entry => {
        console.log(`   - Type: ${entry.type}, Name: ${entry.name}`);
        console.log(`     Parent: ${entry.parent_name || 'N/A'}`);
        console.log(`     Created: ${entry.created_at}`);
        if (entry.text && entry.text.includes('kenal')) {
          console.log(`     Text snippet: ${entry.text.substring(0, 200)}...`);
        }
        console.log('');
      });
    } else {
      console.log('   No entries found in context_embeddings');
    }

    // 2. Search activity_log for Kenal Admin mentions
    console.log('\n2. Searching activity_log for Kenal Admin activities...');
    const activityResults = await supabaseQuery('activity_log',
      '?or=(project_name.ilike.*kenal*,activity_description.ilike.*kenal*,metadata.cs.{"project":"kenal-admin"})&order=created_at.desc&limit=50');
    
    if (activityResults.length > 0) {
      console.log(`   Found ${activityResults.length} activities:`);
      activityResults.forEach(activity => {
        console.log(`   - Type: ${activity.activity_type}`);
        console.log(`     Project: ${activity.project_name}`);
        console.log(`     Description: ${activity.activity_description}`);
        console.log(`     Created: ${activity.created_at}`);
        if (activity.metadata) {
          console.log(`     Metadata: ${JSON.stringify(activity.metadata, null, 2)}`);
        }
        console.log('');
      });
    } else {
      console.log('   No activities found in activity_log');
    }

    // 3. Check for Cursor AI activities
    console.log('\n3. Checking for Cursor AI logging activities...');
    const cursorResults = await supabaseQuery('activity_log',
      '?or=(activity_type.eq.ai_conversation,metadata.cs.{"tool":"cursor"},metadata.cs.{"source":"cursor"})&order=created_at.desc&limit=20');
    
    if (cursorResults.length > 0) {
      console.log(`   Found ${cursorResults.length} Cursor AI activities:`);
      cursorResults.forEach(activity => {
        console.log(`   - Project: ${activity.project_name}`);
        console.log(`     Description: ${activity.activity_description}`);
        console.log(`     Created: ${activity.created_at}`);
        if (activity.metadata) {
          console.log(`     Metadata: ${JSON.stringify(activity.metadata, null, 2)}`);
        }
        console.log('');
      });
    } else {
      console.log('   No Cursor AI activities found');
    }

    // 4. Check current_context for Kenal Admin
    console.log('\n4. Checking current_context for Kenal Admin...');
    const contextResult = await supabaseQuery('current_context',
      '?or=(project_name.ilike.*kenal*,current_task.ilike.*kenal*)');
    
    if (contextResult.length > 0) {
      console.log(`   Found ${contextResult.length} context entries:`);
      contextResult.forEach(context => {
        console.log(`   - User: ${context.user_id}`);
        console.log(`     Project: ${context.project_name}`);
        console.log(`     Current Task: ${context.current_task}`);
        console.log(`     Phase: ${context.current_phase}`);
        console.log(`     Progress: ${context.progress_percentage}%`);
        console.log(`     Last Updated: ${context.last_updated}`);
        console.log('');
      });
    } else {
      console.log('   No current context for Kenal Admin');
    }

  } catch (error) {
    console.error('❌ Error searching database:', error.message);
  }
}

// Execute search
searchKenalMemories().then(() => {
  console.log('\n✅ Search completed');
}).catch(err => {
  console.error('❌ Search failed:', err.message);
});