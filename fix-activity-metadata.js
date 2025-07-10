#!/usr/bin/env node

// Fix inconsistent metadata in FlowState activities
const https = require('https');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function fixActivityMetadata() {
  try {
    // Get FlowState activities with metadata issues
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?project_name=eq.FlowState AI&order=created_at.desc&limit=50`, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const activities = await response.json();
    
    console.log(`Found ${activities.length} FlowState activities to check\n`);
    
    const machineName = os.hostname(); // Get actual machine name
    const toFix = [];
    
    activities.forEach(activity => {
      const metadata = activity.metadata || {};
      let needsFix = false;
      const fixes = {};
      
      // Check for machine issues
      if (!metadata.machine || metadata.machine === 'Unknown Machine') {
        fixes.machine = machineName;
        needsFix = true;
      }
      
      // Normalize tool names
      if (metadata.tool) {
        const normalizedTool = normalizeToolName(metadata.tool);
        if (normalizedTool !== metadata.tool) {
          fixes.tool = normalizedTool;
          needsFix = true;
        }
      }
      
      // Remove duplicate machine_id if it exists
      if (metadata.machine_id) {
        fixes.machine_id = undefined; // Remove it
        needsFix = true;
      }
      
      if (needsFix) {
        toFix.push({
          id: activity.id,
          oldMetadata: metadata,
          newMetadata: { ...metadata, ...fixes }
        });
      }
    });
    
    console.log(`Need to fix ${toFix.length} activities\n`);
    
    if (toFix.length === 0) {
      console.log('✅ All activities have correct metadata!');
      return;
    }
    
    // Fix each activity
    for (const fix of toFix) {
      console.log(`Fixing activity ${fix.id}...`);
      console.log(`  Tool: ${fix.oldMetadata.tool} → ${fix.newMetadata.tool}`);
      console.log(`  Machine: ${fix.oldMetadata.machine || 'Unknown'} → ${fix.newMetadata.machine}`);
      
      const updateResponse = await fetch(`${SUPABASE_URL}/rest/v1/activity_log?id=eq.${fix.id}`, {
        method: 'PATCH',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          metadata: fix.newMetadata
        })
      });
      
      if (updateResponse.ok) {
        console.log('  ✅ Fixed\n');
      } else {
        console.log('  ❌ Failed:', await updateResponse.text(), '\n');
      }
    }
    
    console.log('✅ Metadata cleanup complete!');
    
  } catch (error) {
    console.error('Error fixing metadata:', error);
  }
}

function normalizeToolName(tool) {
  const toolMap = {
    'claude_code': 'Claude Code',
    'Claude Code CLI': 'Claude Code',
    'manual-logger': 'Manual Entry',
    'Claude Desktop': 'Claude Desktop',
    'AI Tool': 'AI Tool'
  };
  
  return toolMap[tool] || tool;
}

fixActivityMetadata();