#!/bin/bash

# Setup FlowState Memory Sync Service

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source config
if [ -f ~/.flowstate/config ]; then
  source ~/.flowstate/config
else
  echo "Error: ~/.flowstate/config not found"
  exit 1
fi

echo "🚀 FlowState Memory Sync Setup"
echo "==============================="

# Create logs directory
mkdir -p ~/.flowstate/logs

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS - Create launchd plist
  PLIST_FILE="$HOME/Library/LaunchAgents/com.flowstate.memory-sync.plist"
  
  cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.flowstate.memory-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>$SCRIPT_DIR/memory-to-activity-sync.js</string>
        <string>--continuous</string>
        <string>--interval</string>
        <string>5</string>
        <string>--project</string>
        <string>flowstate</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>FLOWSTATE_SUPABASE_URL</key>
        <string>$FLOWSTATE_SUPABASE_URL</string>
        <key>FLOWSTATE_SERVICE_KEY</key>
        <string>$FLOWSTATE_SERVICE_KEY</string>
        <key>FLOWSTATE_MACHINE_ID</key>
        <string>$FLOWSTATE_MACHINE_ID</string>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/.flowstate/logs/memory-sync.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.flowstate/logs/memory-sync-error.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

  echo "✅ Created launchd plist: $PLIST_FILE"
  echo ""
  echo "To start the service:"
  echo "  launchctl load $PLIST_FILE"
  echo ""
  echo "To stop the service:"
  echo "  launchctl unload $PLIST_FILE"
  echo ""
  echo "To check status:"
  echo "  launchctl list | grep flowstate"
  
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux - Create systemd service
  SERVICE_FILE="$HOME/.config/systemd/user/flowstate-memory-sync.service"
  mkdir -p "$HOME/.config/systemd/user"
  
  cat > "$SERVICE_FILE" << EOF
[Unit]
Description=FlowState Memory Sync Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node $SCRIPT_DIR/memory-to-activity-sync.js --continuous --interval 5 --project flowstate
Restart=always
RestartSec=10
Environment="FLOWSTATE_SUPABASE_URL=$FLOWSTATE_SUPABASE_URL"
Environment="FLOWSTATE_SERVICE_KEY=$FLOWSTATE_SERVICE_KEY"
Environment="FLOWSTATE_MACHINE_ID=$FLOWSTATE_MACHINE_ID"
StandardOutput=append:$HOME/.flowstate/logs/memory-sync.log
StandardError=append:$HOME/.flowstate/logs/memory-sync-error.log

[Install]
WantedBy=default.target
EOF

  echo "✅ Created systemd service: $SERVICE_FILE"
  echo ""
  echo "To start the service:"
  echo "  systemctl --user daemon-reload"
  echo "  systemctl --user enable flowstate-memory-sync"
  echo "  systemctl --user start flowstate-memory-sync"
  echo ""
  echo "To check status:"
  echo "  systemctl --user status flowstate-memory-sync"
  
else
  echo "⚠️  Unsupported OS. Please run the sync manually:"
  echo "  node $SCRIPT_DIR/memory-to-activity-sync.js --continuous"
fi

echo ""
echo "📝 Manual Commands:"
echo "  Run once:        node memory-to-activity-sync.js --once"
echo "  Run continuous:  node memory-to-activity-sync.js --continuous"
echo "  Quick log:       ./claude-log 'description of activity'"