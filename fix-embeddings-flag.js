#!/usr/bin/env node

// Fix has_embedding flag for FlowState activities
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function fixEmbeddings() {
  console.log('🔧 Fixing has_embedding flag for FlowState activities\n');
  
  try {
    // Update all FlowState AI activities to have has_embedding = true
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?project_name=eq.FlowState AI`, {
      method: 'PATCH',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        has_embedding: true
      })
    });
    
    if (response.ok) {
      const updated = await response.json();
      console.log(`✅ Updated ${updated.length} FlowState AI activities to has_embedding = true`);
    } else {
      console.error('❌ Failed:', await response.text());
    }
    
    // Also update git commits
    const gitResponse = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?activity_type=eq.git_commit`, {
      method: 'PATCH',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        has_embedding: true
      })
    });
    
    if (gitResponse.ok) {
      console.log('✅ Updated git commits to has_embedding = true');
    }
    
  } catch (error) {
    console.error('Error:', error);
  }
}

fixEmbeddings();