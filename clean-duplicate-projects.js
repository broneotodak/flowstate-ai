#!/usr/bin/env node

// Clean up duplicate FlowState project entries in the database
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

async function supabaseRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/${path}`);
    
    const options = {
      method,
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data || '[]'));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function analyzeProjects() {
  console.log('🔍 Analyzing project names in activity_log...\n');
  
  // Get unique project names
  const activities = await supabaseRequest('activity_log?select=project_name&order=created_at.desc&limit=1000');
  const projectCounts = {};
  
  activities.forEach(activity => {
    const project = activity.project_name;
    projectCounts[project] = (projectCounts[project] || 0) + 1;
  });
  
  console.log('Project activity counts:');
  Object.entries(projectCounts)
    .sort((a, b) => b[1] - a[1])
    .forEach(([project, count]) => {
      console.log(`  ${project}: ${count} activities`);
    });
  
  return projectCounts;
}

async function updateProjectNames() {
  console.log('\n🔧 Updating FlowState project names...\n');
  
  const projectMappings = [
    { old: 'flowstate-ai-github', new: 'FlowState AI' },
    { old: 'flowstate-ai', new: 'FlowState AI' },
    { old: 'flowstate', new: 'FlowState AI' }
  ];
  
  for (const mapping of projectMappings) {
    console.log(`Updating ${mapping.old} → ${mapping.new}...`);
    
    try {
      // Update activities
      const updateUrl = `activity_log?project_name=eq.${encodeURIComponent(mapping.old)}`;
      const updateBody = { project_name: mapping.new };
      
      await supabaseRequest(updateUrl, 'PATCH', updateBody);
      console.log(`✅ Updated activities for ${mapping.old}`);
      
      // Update context_embeddings if they exist
      const embedUrl = `context_embeddings?parent_name=eq.${encodeURIComponent(mapping.old)}`;
      const embedBody = { parent_name: mapping.new };
      
      try {
        await supabaseRequest(embedUrl, 'PATCH', embedBody);
        console.log(`✅ Updated embeddings for ${mapping.old}`);
      } catch (e) {
        // Context embeddings might not exist for this project
      }
      
    } catch (error) {
      console.error(`❌ Failed to update ${mapping.old}: ${error.message}`);
    }
  }
}

async function updateMachineNames() {
  console.log('\n🖥️  Updating machine names for consistency...\n');
  
  const machines = await supabaseRequest('user_machines?select=*');
  
  for (const machine of machines) {
    let updated = false;
    let newName = machine.machine_name;
    
    // Normalize browser extension names
    if (machine.machine_name.includes('Extension')) {
      // Already normalized
      continue;
    }
    
    // Check if this is a browser-based machine
    if (machine.metadata?.browser || machine.metadata?.source === 'browser_extension') {
      const browser = machine.metadata?.browser || 'Chrome';
      const os = machine.os || machine.metadata?.os || 'Unknown OS';
      newName = `${browser} Extension (${os})`;
      updated = true;
    }
    
    if (updated) {
      console.log(`Updating machine: ${machine.machine_name} → ${newName}`);
      try {
        await supabaseRequest(
          `user_machines?id=eq.${machine.id}`,
          'PATCH',
          { machine_name: newName }
        );
        console.log(`✅ Updated ${machine.machine_name}`);
      } catch (error) {
        console.error(`❌ Failed to update machine: ${error.message}`);
      }
    }
  }
}

async function main() {
  console.log('🧹 FlowState Project Cleanup Tool\n');
  console.log('This will consolidate duplicate project names and normalize data.\n');
  
  // First analyze current state
  const projectCounts = await analyzeProjects();
  
  // Check if we have duplicates to fix
  const duplicates = ['flowstate-ai-github', 'flowstate-ai', 'flowstate'];
  const hasDuplicates = duplicates.some(name => projectCounts[name] > 0);
  
  if (!hasDuplicates) {
    console.log('\n✨ No duplicate FlowState projects found! Database is clean.');
    return;
  }
  
  // Confirm before proceeding
  console.log('\n⚠️  This will update all FlowState variants to "FlowState AI"');
  console.log('Press Ctrl+C to cancel, or wait 3 seconds to continue...');
  
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Update project names
  await updateProjectNames();
  
  // Also update machine names for consistency
  await updateMachineNames();
  
  // Show final state
  console.log('\n📊 Final project state:');
  await analyzeProjects();
  
  console.log('\n✅ Cleanup complete!');
  console.log('The dashboard will now show consistent project names.');
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { analyzeProjects, updateProjectNames };