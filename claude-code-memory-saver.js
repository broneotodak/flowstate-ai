#!/usr/bin/env node

/**
 * Claude Code Memory Saver
 * 
 * Since Claude Code doesn't automatically save to pgvector memory,
 * this script creates periodic memory snapshots of the current session
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

class ClaudeCodeMemorySaver {
  constructor() {
    this.sessionStartTime = new Date();
    this.lastSaveTime = null;
    this.saveInterval = 5 * 60 * 1000; // Save every 5 minutes
    this.projectName = this.detectProject();
    this.machineName = os.hostname();
  }

  detectProject() {
    const cwd = process.cwd();
    
    // Check for .git folder
    if (fs.existsSync(path.join(cwd, '.git'))) {
      const gitConfig = path.join(cwd, '.git', 'config');
      if (fs.existsSync(gitConfig)) {
        const config = fs.readFileSync(gitConfig, 'utf8');
        const match = config.match(/url = .*\/([^\/\n]+)\.git/);
        if (match) {
          const projectName = match[1];
          if (projectName === 'flowstate-ai' || projectName === 'flowstate-ai-github') {
            return 'FlowState AI';
          }
          return projectName;
        }
      }
    }
    
    const dirName = path.basename(cwd);
    if (dirName === 'flowstate-ai' || dirName === 'flowstate-ai-github') {
      return 'FlowState AI';
    }
    
    return dirName || 'Unknown Project';
  }

  async saveMemory(type, content, metadata = {}) {
    const memory = {
      user_id: 'neo_todak',
      owner: 'neo_todak',
      source: 'claude_desktop', // Has to be this due to constraint
      memory_type: type,
      content: content,
      metadata: {
        ...metadata,
        actual_source: 'claude_code',
        project: this.projectName,
        machine: this.machineName,
        tool: 'Claude Code CLI',
        session_start: this.sessionStartTime.toISOString(),
        saved_at: new Date().toISOString()
      }
    };

    return new Promise((resolve, reject) => {
      const url = new URL(`${SUPABASE_URL}/rest/v1/claude_desktop_memory`);
      const data = JSON.stringify(memory);
      
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
            console.log(`✅ Memory saved: ${type}`);
            resolve();
          } else {
            reject(new Error(`Failed to save memory: ${res.statusCode} ${body}`));
          }
        });
      });

      req.on('error', reject);
      req.write(data);
      req.end();
    });
  }

  async saveSessionMemory() {
    const sessionDuration = Math.floor((Date.now() - this.sessionStartTime) / 1000 / 60);
    
    // Get recent files modified
    let recentFiles = [];
    try {
      const gitStatus = require('child_process').execSync('git status --porcelain 2>/dev/null || echo ""', { encoding: 'utf8' });
      recentFiles = gitStatus.split('\n').filter(line => line.trim()).slice(0, 5);
    } catch (e) {
      // Ignore git errors
    }

    const content = `Working on ${this.projectName}: Active Claude Code development session. 
Session duration: ${sessionDuration} minutes.
Current directory: ${process.cwd()}
${recentFiles.length > 0 ? `\nRecent changes:\n${recentFiles.join('\n')}` : ''}`;

    await this.saveMemory('conversation_summary', content, {
      session_type: 'claude_code_development',
      duration_minutes: sessionDuration,
      recent_files: recentFiles
    });
  }

  async saveActivityMemory(description) {
    const content = `${this.projectName}: ${description}`;
    
    await this.saveMemory('technical_solution', content, {
      activity_type: 'development',
      description: description
    });
  }

  async start() {
    console.log('🧠 Claude Code Memory Saver Started');
    console.log(`📁 Project: ${this.projectName}`);
    console.log(`⏱️  Will save memory every ${this.saveInterval / 1000 / 60} minutes`);
    
    // Save initial session start
    await this.saveActivityMemory('Started Claude Code development session');
    
    // Set up periodic saves
    setInterval(async () => {
      try {
        await this.saveSessionMemory();
        this.lastSaveTime = new Date();
      } catch (error) {
        console.error('❌ Failed to save session memory:', error.message);
      }
    }, this.saveInterval);
    
    // Handle process exit
    process.on('SIGINT', () => this.stop());
    process.on('SIGTERM', () => this.stop());
  }

  async stop() {
    console.log('\n💾 Saving final session memory...');
    try {
      await this.saveActivityMemory('Ended Claude Code development session');
      console.log('✅ Final memory saved');
    } catch (error) {
      console.error('❌ Failed to save final memory:', error.message);
    }
    process.exit(0);
  }
}

// Quick save function for manual use
async function quickSave(description) {
  const saver = new ClaudeCodeMemorySaver();
  try {
    await saver.saveActivityMemory(description);
    console.log('✅ Activity memory saved');
  } catch (error) {
    console.error('❌ Failed to save:', error.message);
  }
}

// Main execution
if (require.main === module) {
  if (!SERVICE_KEY) {
    console.error('❌ FLOWSTATE_SERVICE_KEY not found. Run: source ~/.flowstate/config');
    process.exit(1);
  }

  const args = process.argv.slice(2);
  
  if (args.length > 0) {
    // Quick save mode
    quickSave(args.join(' '));
  } else {
    // Start continuous mode
    const saver = new ClaudeCodeMemorySaver();
    saver.start();
  }
}

module.exports = { ClaudeCodeMemorySaver, quickSave };