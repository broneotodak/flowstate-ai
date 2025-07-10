#!/usr/bin/env node

// Check claude_desktop_memory structure
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function checkMemoryStructure() {
  try {
    // Get recent memories
    const response = await fetch(`${SUPABASE_URL}/rest/v1/claude_desktop_memory?order=created_at.desc&limit=5`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const memories = await response.json();
    
    console.log('=== Claude Desktop Memory Structure ===\n');
    console.log(`Found ${memories.length} recent memories\n`);
    
    memories.forEach((memory, index) => {
      console.log(`Memory ${index + 1}:`);
      console.log('ID:', memory.id);
      console.log('Created:', new Date(memory.created_at).toLocaleString());
      console.log('Content Type:', memory.content_type);
      console.log('Tool:', memory.tool_name);
      console.log('Operation:', memory.operation_type);
      
      // Show content structure
      console.log('\nContent Structure:');
      if (memory.content) {
        try {
          const content = typeof memory.content === 'string' ? JSON.parse(memory.content) : memory.content;
          console.log(JSON.stringify(content, null, 2).substring(0, 500) + '...');
        } catch (e) {
          // Content might not be JSON
          console.log('Raw content:', typeof memory.content === 'string' ? memory.content.substring(0, 500) + '...' : memory.content);
        }
      }
      
      // Show metadata
      if (memory.metadata) {
        console.log('\nMetadata:');
        console.log(JSON.stringify(memory.metadata, null, 2));
      }
      
      console.log('\n' + '='.repeat(50) + '\n');
    });

    // Also check table schema
    console.log('\nChecking table columns...');
    const schemaResponse = await fetch(`${SUPABASE_URL}/rest/v1/claude_desktop_memory?limit=0`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'count=exact'
      }
    });

    console.log('Total records in claude_desktop_memory:', schemaResponse.headers.get('content-range'));

  } catch (error) {
    console.error('Error checking memory structure:', error);
  }
}

checkMemoryStructure();