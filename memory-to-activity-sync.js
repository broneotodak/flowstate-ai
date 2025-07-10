#!/usr/bin/env node

// FlowState Memory to Activity Intelligent Sync
// Monitors claude_desktop_memory and syncs to activity_log

const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;
const MACHINE_ID = process.env.FLOWSTATE_MACHINE_ID || '2'; // Default to mac

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

// Track last processed memory ID
let lastProcessedId = null;

// Project name normalization map
const PROJECT_NORMALIZATION = {
  'flowstate-ai': 'FlowState AI',
  'flowstate': 'FlowState AI',
  'claude-n': 'ClaudeN',
  'clauden': 'ClaudeN',
  'todak': 'TODAK',
  'todak-ai': 'TODAK AI',
  'kaia': 'KAIA',
  'kaia-ai': 'KAIA AI',
  'yet': null, // Ignore generic words
  'cards': null,
  'test': null
};

// Tool mapping for proper source attribution
const TOOL_MAPPING = {
  'Claude Desktop': 'Claude Desktop',
  'Claude Code CLI': 'Claude Code',
  'claude_code': 'Claude Code',
  'Cursor': 'Cursor',
  'cursor': 'Cursor',
  'VS Code': 'VS Code',
  'manual': 'Manual Entry'
};

// Normalize project name
function normalizeProjectName(projectName) {
  if (!projectName) return null;
  
  const lower = projectName.toLowerCase().trim();
  
  // Check normalization map
  if (PROJECT_NORMALIZATION.hasOwnProperty(lower)) {
    return PROJECT_NORMALIZATION[lower];
  }
  
  // Check if it contains known project keywords
  for (const [key, normalized] of Object.entries(PROJECT_NORMALIZATION)) {
    if (normalized && lower.includes(key)) {
      return normalized;
    }
  }
  
  // If it looks like a valid project name, return it
  if (projectName.length > 2 && !projectName.match(/^(the|and|or|but|with|for|to|in|on|at|by)$/i)) {
    // Capitalize properly
    return projectName.split(/[\s-]/).map(word => 
      word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
    ).join(' ');
  }
  
  return null;
}

// Extract project from memory content and metadata
function extractProjectInfo(memory) {
  let project = null;
  let tool = 'AI Tool';
  let activityType = 'development';
  
  // First check metadata
  if (memory.metadata) {
    if (memory.metadata.project) {
      project = normalizeProjectName(memory.metadata.project);
    }
    
    if (memory.metadata.tool) {
      tool = TOOL_MAPPING[memory.metadata.tool] || memory.metadata.tool;
    } else if (memory.metadata.actual_source) {
      tool = TOOL_MAPPING[memory.metadata.actual_source] || memory.metadata.actual_source;
    }
    
    if (memory.metadata.activity_type) {
      activityType = memory.metadata.activity_type;
    }
  }
  
  // If no project in metadata, try to extract from content
  if (!project && memory.content) {
    const content = memory.content.toString();
    
    // Look for patterns like "Working on ProjectName:" or "ProjectName:"
    const projectPatterns = [
      /Working on ([^:]+):/i,
      /^([^:]+):/,
      /Project:\s*([^,\n]+)/i,
      /\bfor\s+([A-Z][a-zA-Z\s]+)(?:\s+project)?/
    ];
    
    for (const pattern of projectPatterns) {
      const match = content.match(pattern);
      if (match) {
        const extracted = normalizeProjectName(match[1].trim());
        if (extracted) {
          project = extracted;
          break;
        }
      }
    }
  }
  
  // Determine activity type from content if not specified
  if (activityType === 'development' && memory.content) {
    const content = memory.content.toLowerCase();
    if (content.includes('fix') || content.includes('bug') || content.includes('error')) {
      activityType = 'debugging';
    } else if (content.includes('deploy') || content.includes('build')) {
      activityType = 'deployment';
    } else if (content.includes('test')) {
      activityType = 'testing';
    } else if (content.includes('doc') || content.includes('readme')) {
      activityType = 'documentation';
    }
  }
  
  return { project, tool, activityType };
}

// Create activity from memory
function createActivityFromMemory(memory) {
  const { project, tool, activityType } = extractProjectInfo(memory);
  
  // Skip if no valid project found
  if (!project) {
    console.log(`⚠️  Skipping memory ${memory.id} - no valid project found`);
    return null;
  }
  
  // Create description
  let description = memory.content;
  if (description && description.length > 255) {
    description = description.substring(0, 252) + '...';
  }
  
  return {
    user_id: 'neo_todak', // Default user
    project_name: project,
    activity_type: activityType,
    activity_description: description || `${tool} activity`,
    metadata: {
      source: 'memory_sync',
      tool: tool,
      memory_id: memory.id,
      machine: memory.metadata?.machine || require('os').hostname(), // Preserve original machine // Use actual machine name
      timestamp: memory.created_at
    }
  };
}

// Sync single memory to activity
async function syncMemoryToActivity(memory) {
  const activity = createActivityFromMemory(memory);
  
  if (!activity) {
    return false;
  }
  
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
      console.log(`✅ Synced: ${activity.project_name} - ${activity.activity_description?.substring(0, 50)}...`);
      return true;
    } else {
      const error = await response.text();
      console.error(`❌ Failed to sync memory ${memory.id}:`, error);
      return false;
    }
  } catch (error) {
    console.error(`❌ Error syncing memory ${memory.id}:`, error.message);
    return false;
  }
}

// Get unprocessed memories
async function getUnprocessedMemories(projectFilter = null) {
  try {
    // Build query
    let query = `${SUPABASE_URL}/rest/v1/claude_desktop_memory?order=created_at.desc`;
    
    // If we have a last processed ID, only get newer ones
    if (lastProcessedId) {
      query += `&id=gt.${lastProcessedId}`;
    }
    
    // Get more memories if filtering by project
    query += projectFilter ? '&limit=50' : '&limit=10';
    
    const response = await fetch(query, {
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    let memories = await response.json();
    
    // Filter by project in JavaScript if specified
    if (projectFilter) {
      memories = memories.filter(memory => {
        if (!memory.metadata || !memory.metadata.project) return false;
        return memory.metadata.project.toLowerCase().includes(projectFilter.toLowerCase());
      });
    }
    
    return memories;
  } catch (error) {
    console.error('Error fetching memories:', error);
    return [];
  }
}

// Update machine last active time
async function updateMachineActivity() {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/user_machines?id=eq.${MACHINE_ID}`, {
      method: 'PATCH',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        last_active: new Date().toISOString()
      })
    });
    
    if (response.ok) {
      console.log('✅ Updated machine last active time');
    }
  } catch (error) {
    console.error('Error updating machine activity:', error);
  }
}

// Main sync loop
async function runSync(projectFilter = null) {
  console.log('🔄 Starting memory to activity sync...');
  if (projectFilter) {
    console.log(`📁 Filtering for project: ${projectFilter}`);
  }
  console.log('');
  
  const memories = await getUnprocessedMemories(projectFilter);
  
  if (memories.length === 0) {
    console.log('No new memories to process');
    return;
  }
  
  console.log(`Found ${memories.length} memories to process\n`);
  
  let successCount = 0;
  
  for (const memory of memories) {
    const success = await syncMemoryToActivity(memory);
    if (success) {
      successCount++;
      lastProcessedId = memory.id;
    }
  }
  
  console.log(`\n✅ Synced ${successCount} of ${memories.length} memories`);
  
  // Update machine activity if we synced anything
  if (successCount > 0) {
    await updateMachineActivity();
  }
}

// Continuous monitoring mode
async function startContinuousSync(intervalMinutes = 5, projectFilter = null) {
  console.log(`🚀 Starting continuous sync (checking every ${intervalMinutes} minutes)`);
  if (projectFilter) {
    console.log(`📁 Filtering for project: ${projectFilter}`);
  }
  console.log('\n');
  
  // Run initial sync
  await runSync(projectFilter);
  
  // Set up interval
  setInterval(async () => {
    console.log(`\n${'='.repeat(60)}\n`);
    await runSync(projectFilter);
  }, intervalMinutes * 60 * 1000);
}

// Check command line arguments
const args = process.argv.slice(2);

// Parse project filter
const projectIndex = args.indexOf('--project');
const projectFilter = projectIndex !== -1 && args[projectIndex + 1] 
  ? args[projectIndex + 1] 
  : null;

if (args.includes('--once')) {
  // Run once and exit
  runSync(projectFilter).then(() => {
    console.log('\n✅ Sync complete');
    process.exit(0);
  });
} else if (args.includes('--continuous')) {
  // Run continuously
  const intervalIndex = args.indexOf('--interval');
  const interval = intervalIndex !== -1 && args[intervalIndex + 1] 
    ? parseInt(args[intervalIndex + 1]) 
    : 5;
  
  startContinuousSync(interval, projectFilter);
} else {
  console.log('FlowState Memory to Activity Sync');
  console.log('==================================\n');
  console.log('Usage:');
  console.log('  node memory-to-activity-sync.js --once                    # Run once and exit');
  console.log('  node memory-to-activity-sync.js --once --project flowstate  # Filter by project');
  console.log('  node memory-to-activity-sync.js --continuous              # Run continuously (default: 5 min)');
  console.log('  node memory-to-activity-sync.js --continuous --interval 10 --project flowstate\n');
  console.log('Options:');
  console.log('  --project <name>    Filter memories by project name');
  console.log('  --interval <min>    Set sync interval in minutes (default: 5)\n');
  console.log('This tool syncs memories from claude_desktop_memory to activity_log');
  console.log('It intelligently extracts project names and creates proper activities');
}