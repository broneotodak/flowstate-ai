#!/bin/bash

# FlowState Complete Setup Script
# This sets up automatic tracking for all your development tools

echo "🌊 FlowState Complete Setup"
echo "=========================="

# Check if service key is set
if [ -z "$FLOWSTATE_SERVICE_KEY" ]; then
  echo "❌ FLOWSTATE_SERVICE_KEY not set!"
  echo "Please run: export FLOWSTATE_SERVICE_KEY='your-service-key'"
  exit 1
fi

# Test the service key
echo "Testing service key..."
node /Users/broneotodak/test-flowstate-api.js > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Service key test failed!"
  exit 1
fi
echo "✅ Service key valid"

# 1. Install git hooks globally
echo ""
echo "Installing Git hooks..."
~/.flowstate/install-global.sh

# 2. Set up shell tracking
echo ""
echo "Setting up shell tracking..."
cat >> ~/.zshrc << 'EOF'

# FlowState Shell Tracking
flowstate_log_command() {
  local exit_code=$?
  local last_command=$(fc -ln -1)
  
  if [ -n "$FLOWSTATE_SERVICE_KEY" ] && [ "$last_command" != "flowstate_log_command" ]; then
    (
      node -e "
        const https = require('https');
        const os = require('os');
        const command = process.argv[1];
        const project = process.cwd().split('/').pop();
        
        const data = JSON.stringify({
          user_id: 'neo_todak',
          activity_type: 'terminal_command',
          description: 'Terminal: ' + command.substring(0, 100),
          project: project,
          metadata: {
            command: command,
            cwd: process.cwd(),
            machine_name: os.hostname(),
            source: 'shell_tracking'
          }
        });
        
        const url = new URL('https://YOUR_PROJECT_ID.supabase.co/rest/v1/activities');
        const req = https.request({
          hostname: url.hostname,
          path: url.pathname,
          method: 'POST',
          headers: {
            'apikey': '$FLOWSTATE_SERVICE_KEY',
            'Authorization': 'Bearer $FLOWSTATE_SERVICE_KEY',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
          }
        });
        req.write(data);
        req.end();
      " "$last_command" 2>/dev/null &
    )
  fi
  return $exit_code
}

# Enable for important commands only (to avoid noise)
alias gs='git status; flowstate_log_command'
alias gc='git commit; flowstate_log_command'
alias gp='git push; flowstate_log_command'
alias npm='npm; flowstate_log_command'
alias yarn='yarn; flowstate_log_command'
EOF

# 3. Create VSCode extension settings
echo ""
echo "Creating VSCode integration..."
mkdir -p ~/.vscode/extensions/flowstate-tracker
cat > ~/.vscode/extensions/flowstate-tracker/extension.js << 'EOF'
const vscode = require('vscode');
const FlowStateLogger = require('/Users/broneotodak/flowstate-universal-logger');

function activate(context) {
    const logger = new FlowStateLogger({
        serviceKey: process.env.FLOWSTATE_SERVICE_KEY,
        toolName: 'vscode'
    });

    // Track file saves
    vscode.workspace.onDidSaveTextDocument(async (document) => {
        await logger.logCodeEdit(document.fileName, {
            project: vscode.workspace.name || 'Unknown Project'
        });
    });

    // Track active file changes
    vscode.window.onDidChangeActiveTextEditor(async (editor) => {
        if (editor) {
            await logger.updateContext({
                project: vscode.workspace.name,
                task: `Editing ${editor.document.fileName}`,
                phase: 'Development'
            });
        }
    });
}

exports.activate = activate;
EOF

# 4. Create a daemon for continuous tracking
echo ""
echo "Creating FlowState daemon..."
cat > ~/.flowstate/flowstate-daemon.js << 'EOF'
#!/usr/bin/env node

// FlowState Daemon - Monitors system activity
const fs = require('fs');
const os = require('os');
const { exec } = require('child_process');
const FlowStateLogger = require('/Users/broneotodak/flowstate-universal-logger');

const logger = new FlowStateLogger({
    serviceKey: process.env.FLOWSTATE_SERVICE_KEY,
    toolName: 'system-monitor'
});

let lastActivity = null;

// Monitor active window/application
function checkActiveApp() {
    exec('osascript -e \'tell application "System Events" to get name of first application process whose frontmost is true\'', 
    (err, stdout) => {
        if (!err) {
            const app = stdout.trim();
            if (app !== lastActivity) {
                lastActivity = app;
                
                // Log significant app switches
                if (['Code', 'Terminal', 'iTerm2', 'Chrome', 'Safari'].includes(app)) {
                    logger.logActivity({
                        type: 'app_switch',
                        description: `Switched to ${app}`,
                        metadata: { app }
                    });
                }
            }
        }
    });
}

// Run checks
setInterval(checkActiveApp, 30000); // Every 30 seconds

console.log('FlowState daemon started');
EOF

chmod +x ~/.flowstate/flowstate-daemon.js

# 5. Create launch script
cat > ~/.flowstate/start-tracking.sh << 'EOF'
#!/bin/bash

# Start FlowState tracking

if [ -z "$FLOWSTATE_SERVICE_KEY" ]; then
  echo "❌ Please set FLOWSTATE_SERVICE_KEY"
  exit 1
fi

# Start daemon in background
nohup ~/.flowstate/flowstate-daemon.js > ~/.flowstate/daemon.log 2>&1 &
echo $! > ~/.flowstate/daemon.pid

echo "✅ FlowState tracking started (PID: $(cat ~/.flowstate/daemon.pid))"
EOF

chmod +x ~/.flowstate/start-tracking.sh

# 6. Create stop script
cat > ~/.flowstate/stop-tracking.sh << 'EOF'
#!/bin/bash

if [ -f ~/.flowstate/daemon.pid ]; then
  kill $(cat ~/.flowstate/daemon.pid) 2>/dev/null
  rm ~/.flowstate/daemon.pid
  echo "✅ FlowState tracking stopped"
else
  echo "❌ FlowState daemon not running"
fi
EOF

chmod +x ~/.flowstate/stop-tracking.sh

echo ""
echo "✅ FlowState Complete Setup Done!"
echo ""
echo "What's been set up:"
echo "  • Browser extension fixed (auto-detects all GitHub repos)"
echo "  • Git hooks for automatic commit/push tracking"
echo "  • Shell command tracking (for git, npm, yarn)"
echo "  • VSCode integration ready"
echo "  • System activity daemon"
echo ""
echo "To start tracking:"
echo "  1. Reload your browser extension"
echo "  2. Run: source ~/.zshrc"
echo "  3. Start daemon: ~/.flowstate/start-tracking.sh"
echo ""
echo "Your FlowState dashboard will now show ALL your activity!"