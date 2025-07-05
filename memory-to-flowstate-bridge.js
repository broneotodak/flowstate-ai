#!/usr/bin/env node

/**
 * Memory to FlowState Bridge
 * 
 * This service monitors claude_desktop_memory and context_embeddings tables
 * and automatically creates corresponding activities in FlowState activity_log
 * 
 * This ensures ALL AI tool interactions show up in FlowState dashboard
 */

const https = require('https');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

class MemoryToFlowStateBridge {
  constructor() {
    this.lastCheckedMemory = null;
    this.lastCheckedEmbedding = null;
    this.checkInterval = 30000; // Check every 30 seconds
    this.isRunning = false;
  }

  async init() {
    if (!SERVICE_KEY) {
      console.error('❌ FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
      process.exit(1);
    }

    // Get the last synced timestamps
    await this.loadLastSyncState();
    console.log('🌉 Memory to FlowState Bridge initialized');
    console.log(`📍 Monitoring: claude_desktop_memory & context_embeddings`);
    console.log(`⏱️  Check interval: ${this.checkInterval / 1000} seconds`);
  }

  async loadLastSyncState() {
    try {
      // Try to get the most recent sync marker
      const marker = await this.fetchData(
        `activity_log?activity_type=eq.memory_sync&order=created_at.desc&limit=1`
      );
      
      if (marker && marker.length > 0) {
        const metadata = marker[0].metadata || {};
        this.lastCheckedMemory = metadata.last_memory_sync;
        this.lastCheckedEmbedding = metadata.last_embedding_sync;
        console.log(`📅 Resuming from last sync: ${this.lastCheckedMemory || 'beginning'}`);
      } else {
        // First time running - sync from 24 hours ago
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
        this.lastCheckedMemory = yesterday;
        this.lastCheckedEmbedding = yesterday;
        console.log('🆕 First time sync - starting from 24 hours ago');
      }
    } catch (error) {
      console.error('⚠️  Could not load sync state, starting fresh');
      const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
      this.lastCheckedMemory = yesterday;
      this.lastCheckedEmbedding = yesterday;
    }
  }

  async fetchData(endpoint) {
    return new Promise((resolve, reject) => {
      const url = new URL(`${SUPABASE_URL}/rest/v1/${endpoint}`);
      
      https.get(url, {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Accept': 'application/json'
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(JSON.parse(data || '[]'));
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      }).on('error', reject);
    });
  }

  async createActivity(activity) {
    return new Promise((resolve, reject) => {
      const url = new URL(`${SUPABASE_URL}/rest/v1/activity_log`);
      const data = JSON.stringify(activity);
      
      const req = https.request(url, {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Content-Length': data.length
        }
      }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve();
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${body}`));
          }
        });
      });

      req.on('error', reject);
      req.write(data);
      req.end();
    });
  }

  extractProjectFromMemory(memory) {
    const content = memory.content || '';
    const metadata = memory.metadata || {};
    
    // Check metadata first
    if (metadata.project_name) return metadata.project_name;
    if (metadata.project) return metadata.project;
    
    // Try to extract from content
    const projectPatterns = [
      /project[:\s]+([^\s,\n]+)/i,
      /working on ([^\s,\n]+)/i,
      /repository[:\s]+([^\s,\n]+)/i,
      /repo[:\s]+([^\s,\n]+)/i
    ];
    
    for (const pattern of projectPatterns) {
      const match = content.match(pattern);
      if (match) {
        const project = match[1].replace(/['"]/g, '');
        // Normalize FlowState variants
        if (project.includes('flowstate')) {
          return 'FlowState AI';
        }
        return project;
      }
    }
    
    // Check if it's a known project in content
    const knownProjects = ['FlowState', 'kenal-admin', 'TODAK', 'VentureCanvas', 'Claude'];
    for (const project of knownProjects) {
      if (content.toLowerCase().includes(project.toLowerCase())) {
        return project === 'FlowState' ? 'FlowState AI' : project;
      }
    }
    
    return 'Unknown Project';
  }

  getActivityDescription(memory) {
    const type = memory.memory_type || memory.type || 'unknown';
    const source = memory.source || 'unknown';
    
    // Create meaningful descriptions based on memory type
    const typeDescriptions = {
      'conversation_summary': 'AI conversation session',
      'technical_solution': 'Implemented technical solution',
      'project_milestone': 'Reached project milestone',
      'code_snippet': 'Generated code snippet',
      'error_resolution': 'Resolved error or issue',
      'learning': 'Learned new concept',
      'task_completion': 'Completed task',
      'feature_implementation': 'Implemented new feature',
      'bug_fix': 'Fixed bug',
      'refactoring': 'Refactored code',
      'documentation': 'Updated documentation',
      'research': 'Conducted research',
      'planning': 'Project planning session'
    };
    
    const baseDescription = typeDescriptions[type] || `AI ${type.replace(/_/g, ' ')}`;
    const toolName = this.getToolName(source);
    
    return `${baseDescription} with ${toolName}`;
  }

  getToolName(source) {
    const toolMap = {
      'claude_desktop': 'Claude Desktop',
      'claude_code': 'Claude Code',
      'cursor': 'Cursor AI',
      'vscode': 'VSCode + Claude',
      'browser_extension': 'Browser Extension',
      'github_copilot': 'GitHub Copilot',
      'n8n': 'n8n Workflow'
    };
    
    return toolMap[source] || source;
  }

  async syncClaudeMemories() {
    try {
      // Fetch new memories since last check
      const memories = await this.fetchData(
        `claude_desktop_memory?created_at=gt.${this.lastCheckedMemory}&order=created_at.asc&limit=50`
      );
      
      if (memories.length === 0) return 0;
      
      console.log(`\n📝 Found ${memories.length} new memories to sync`);
      
      for (const memory of memories) {
        try {
          const project = this.extractProjectFromMemory(memory);
          const description = this.getActivityDescription(memory);
          
          const activity = {
            user_id: memory.user_id || memory.owner || 'neo_todak',
            project_name: project,
            activity_type: 'ai_conversation',
            activity_description: description,
            metadata: {
              source: memory.source || 'claude_desktop',
              memory_id: memory.id,
              memory_type: memory.memory_type,
              tool: this.getToolName(memory.source || 'claude_desktop'),
              machine: memory.metadata?.machine || 'Unknown Machine',
              synced_from: 'claude_desktop_memory',
              original_metadata: memory.metadata
            }
          };
          
          await this.createActivity(activity);
          console.log(`   ✅ ${project}: ${description}`);
          
        } catch (error) {
          console.error(`   ❌ Failed to sync memory ${memory.id}:`, error.message);
        }
      }
      
      // Update last checked timestamp
      this.lastCheckedMemory = memories[memories.length - 1].created_at;
      
      return memories.length;
    } catch (error) {
      console.error('❌ Error syncing Claude memories:', error.message);
      return 0;
    }
  }

  async syncContextEmbeddings() {
    try {
      // Skip activity type embeddings (they're already in activity_log)
      const embeddings = await this.fetchData(
        `context_embeddings?created_at=gt.${this.lastCheckedEmbedding}&type=neq.activity&order=created_at.asc&limit=50`
      );
      
      if (embeddings.length === 0) return 0;
      
      console.log(`\n🔗 Found ${embeddings.length} new embeddings to sync`);
      
      for (const embedding of embeddings) {
        try {
          // Skip certain types that aren't activities
          if (['critical_documentation', 'system_message', 'configuration'].includes(embedding.type)) {
            continue;
          }
          
          const project = embedding.parent_name || 'Unknown Project';
          const normalizedProject = project.includes('flowstate') ? 'FlowState AI' : project;
          
          const activity = {
            user_id: 'neo_todak',
            project_name: normalizedProject,
            activity_type: embedding.type || 'ai_activity',
            activity_description: embedding.name || 'AI activity',
            metadata: {
              source: embedding.metadata?.source || 'unknown',
              embedding_id: embedding.id,
              embedding_type: embedding.type,
              tool: embedding.metadata?.tool || 'Unknown Tool',
              machine: embedding.metadata?.machine || os.hostname(),
              synced_from: 'context_embeddings',
              original_metadata: embedding.metadata
            }
          };
          
          await this.createActivity(activity);
          console.log(`   ✅ ${normalizedProject}: ${embedding.name}`);
          
        } catch (error) {
          console.error(`   ❌ Failed to sync embedding:`, error.message);
        }
      }
      
      // Update last checked timestamp
      this.lastCheckedEmbedding = embeddings[embeddings.length - 1].created_at;
      
      return embeddings.length;
    } catch (error) {
      console.error('❌ Error syncing embeddings:', error.message);
      return 0;
    }
  }

  async saveSyncState() {
    try {
      // Save a marker of where we synced up to
      const marker = {
        user_id: 'neo_todak',
        project_name: 'FlowState AI',
        activity_type: 'memory_sync',
        activity_description: 'Memory to FlowState bridge sync checkpoint',
        metadata: {
          last_memory_sync: this.lastCheckedMemory,
          last_embedding_sync: this.lastCheckedEmbedding,
          synced_at: new Date().toISOString(),
          machine: os.hostname()
        }
      };
      
      await this.createActivity(marker);
    } catch (error) {
      console.error('⚠️  Could not save sync state:', error.message);
    }
  }

  async runSyncCycle() {
    console.log(`\n🔄 Running sync cycle at ${new Date().toLocaleTimeString()}`);
    
    let totalSynced = 0;
    
    // Sync both memory sources
    totalSynced += await this.syncClaudeMemories();
    totalSynced += await this.syncContextEmbeddings();
    
    if (totalSynced > 0) {
      console.log(`\n✨ Synced ${totalSynced} total activities to FlowState`);
      await this.saveSyncState();
    } else {
      console.log('💤 No new activities to sync');
    }
  }

  async start() {
    this.isRunning = true;
    
    // Run initial sync
    await this.runSyncCycle();
    
    // Set up periodic sync
    const syncLoop = setInterval(async () => {
      if (!this.isRunning) {
        clearInterval(syncLoop);
        return;
      }
      
      await this.runSyncCycle();
    }, this.checkInterval);
    
    // Handle graceful shutdown
    process.on('SIGINT', () => this.stop());
    process.on('SIGTERM', () => this.stop());
  }

  async stop() {
    console.log('\n🛑 Stopping Memory to FlowState Bridge...');
    this.isRunning = false;
    await this.saveSyncState();
    console.log('👋 Bridge stopped gracefully');
    process.exit(0);
  }
}

// Main execution
async function main() {
  console.log('🌉 Memory to FlowState Bridge');
  console.log('================================');
  console.log('This service syncs AI tool memories to FlowState dashboard\n');
  
  const bridge = new MemoryToFlowStateBridge();
  await bridge.init();
  
  // Check for one-time sync mode
  if (process.argv.includes('--once')) {
    console.log('🔄 Running one-time sync...');
    await bridge.runSyncCycle();
    console.log('✅ One-time sync complete');
    process.exit(0);
  }
  
  // Start continuous sync
  console.log('\n🚀 Starting continuous sync...');
  await bridge.start();
}

if (require.main === module) {
  main().catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });
}

module.exports = MemoryToFlowStateBridge;