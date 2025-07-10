#!/usr/bin/env node

// Claude Code FlowState Integration
// This script enables Claude Code to automatically log activities to FlowState

const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://YOUR_PROJECT_ID.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

class ClaudeCodeFlowStateLogger {
  constructor() {
    this.projectName = this.detectProject();
    this.machineName = os.hostname();
    this.lastActivity = null;
    this.activityBuffer = [];
    this.flushInterval = 30000; // Flush every 30 seconds
  }

  detectProject() {
    // Try to detect project from current directory
    const cwd = process.cwd();
    
    // Check for .git folder
    if (fs.existsSync(path.join(cwd, '.git'))) {
      const gitConfig = path.join(cwd, '.git', 'config');
      if (fs.existsSync(gitConfig)) {
        const config = fs.readFileSync(gitConfig, 'utf8');
        const match = config.match(/url = .*\/([^\/\n]+)\.git/);
        if (match) {
          const projectName = match[1];
          // Normalize FlowState project names
          if (projectName === 'flowstate-ai' || projectName === 'flowstate-ai-github') {
            return 'FlowState AI';
          }
          return projectName;
        }
      }
    }
    
    // Fall back to directory name
    const dirName = path.basename(cwd);
    if (dirName === 'flowstate-ai' || dirName === 'flowstate-ai-github') {
      return 'FlowState AI';
    }
    
    return dirName || 'Unknown Project';
  }

  async logActivity(type, description, metadata = {}) {
    if (!SERVICE_KEY) {
      console.error('FlowState: No SERVICE_KEY found. Activities not logged.');
      return;
    }

    const activity = {
      user_id: 'neo_todak',
      project_name: this.projectName,
      activity_type: type,
      activity_description: description,
      metadata: {
        ...metadata,
        source: 'claude_code',
        machine: this.machineName,
        tool: 'Claude Code CLI',
        timestamp: new Date().toISOString()
      }
    };

    // Buffer activities to avoid spamming
    this.activityBuffer.push(activity);
    
    // Auto-flush if buffer gets large
    if (this.activityBuffer.length >= 5) {
      await this.flush();
    }
  }

  async flush() {
    if (this.activityBuffer.length === 0) return;

    const activities = [...this.activityBuffer];
    this.activityBuffer = [];

    for (const activity of activities) {
      try {
        await this.sendActivity(activity);
      } catch (error) {
        console.error('FlowState: Failed to log activity:', error.message);
      }
    }
  }

  async sendActivity(activity) {
    return new Promise((resolve, reject) => {
      const url = new URL(`${SUPABASE_URL}/rest/v1/activity_log`);
      const data = JSON.stringify(activity);
      
      const options = {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Content-Length': data.length
        }
      };

      const req = https.request(url, options, (res) => {
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

  // Log different types of activities
  async logConversationStart(summary) {
    await this.logActivity('ai_conversation', `Started Claude Code session: ${summary}`, {
      action: 'conversation_start'
    });
  }

  async logFileEdit(filePath, action) {
    await this.logActivity('file_edit', `${action} ${path.basename(filePath)}`, {
      file_path: filePath,
      action: action.toLowerCase()
    });
  }

  async logCommand(command) {
    await this.logActivity('terminal_command', `Executed: ${command.slice(0, 100)}...`, {
      command: command
    });
  }

  async logCodeGeneration(description) {
    await this.logActivity('code_generation', description, {
      generator: 'claude_code'
    });
  }

  // Start periodic flushing
  startAutoFlush() {
    setInterval(() => {
      this.flush().catch(console.error);
    }, this.flushInterval);
  }
}

// Example usage and hook setup
if (require.main === module) {
  const logger = new ClaudeCodeFlowStateLogger();
  
  // Log current session
  logger.logConversationStart('Working on FlowState AI project').then(() => {
    console.log('✅ Claude Code activity logged to FlowState');
    process.exit(0);
  }).catch(err => {
    console.error('❌ Failed to log:', err.message);
    process.exit(1);
  });
}

module.exports = ClaudeCodeFlowStateLogger;