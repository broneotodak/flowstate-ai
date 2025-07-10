#!/usr/bin/env node

// Unified FlowState Logger - Writes directly to context_embeddings
const https = require('https');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

if (!SERVICE_KEY) {
  console.error('Error: FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
  process.exit(1);
}

class UnifiedFlowStateLogger {
  constructor(toolName = 'Unknown') {
    this.toolName = toolName;
    this.machineId = os.hostname();
  }

  async logActivity(activity) {
    // Use RPC function for unified logging
    const payload = {
      p_user_id: 'neo_todak',
      p_project_name: activity.project || this.detectProject(),
      p_activity_type: activity.type || 'activity',
      p_activity_description: activity.description,
      p_machine: this.machineId,
      p_source: activity.source || this.toolName,
      p_tool: activity.tool || this.toolName,
      p_importance: activity.importance || 'normal',
      p_additional_metadata: activity.metadata || {}
    };

    try {
      const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/log_activity_unified`, {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Failed to log: ${error}`);
      }

      const result = await response.json();
      console.log('✅ Activity logged to unified memory');
      return { success: true, data: result };
    } catch (error) {
      console.error('❌ Logging error:', error.message);
      
      // Fallback: Direct insert to context_embeddings
      return this.directInsert(activity);
    }
  }

  async directInsert(activity) {
    const timestamp = new Date().toISOString();
    const payload = {
      type: 'activity',
      name: `${activity.type || 'activity'}_${timestamp}`,
      parent_name: activity.project || 'Unknown',
      metadata: {
        user_id: 'neo_todak',
        activity_type: activity.type || 'activity',
        activity_description: activity.description,
        machine: this.machineId,
        source: activity.source || this.toolName,
        tool: activity.tool || this.toolName,
        importance: activity.importance || 'normal',
        ...activity.metadata
      },
      embedding: null
    };

    try {
      const response = await fetch(`${SUPABASE_URL}/rest/v1/context_embeddings`, {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Direct insert failed: ${error}`);
      }

      console.log('✅ Activity logged via direct insert');
      return { success: true };
    } catch (error) {
      console.error('❌ Direct insert error:', error.message);
      return { success: false, error: error.message };
    }
  }

  detectProject() {
    // Try to detect project from current directory
    const cwd = process.cwd();
    const parts = cwd.split('/');
    const projectFolder = parts[parts.length - 1];
    return projectFolder || 'Unknown';
  }
}

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log('Unified FlowState Logger');
    console.log('Usage: node unified-flowstate-logger.js [project] [type] [description] [importance]');
    console.log('Example: node unified-flowstate-logger.js kenal-admin development "Building user management" high');
    process.exit(0);
  }

  const [project, type, description, importance] = args;
  const logger = new UnifiedFlowStateLogger('CLI');
  
  logger.logActivity({
    project: project || 'Unknown',
    type: type || 'activity',
    description: description || 'Manual activity',
    importance: importance || 'normal',
    source: 'CLI',
    tool: 'unified-flowstate-logger'
  }).then(result => {
    if (result.success) {
      console.log('Activity logged successfully!');
    }
  });
}

module.exports = UnifiedFlowStateLogger;