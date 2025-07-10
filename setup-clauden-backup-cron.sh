#!/bin/bash

# Setup automatic daily backups for ClaudeN memories

BACKUP_SCRIPT="/Users/broneotodak/Projects/flowstate-ai/backup-clauden-memory.sh"
CRON_TIME="0 3 * * *"  # 3 AM daily

echo "🔧 Setting up automatic ClaudeN memory backups..."

# Create a LaunchAgent for macOS (better than cron on Mac)
PLIST_FILE="$HOME/Library/LaunchAgents/com.neotodak.clauden-backup.plist"

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.neotodak.clauden-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$BACKUP_SCRIPT</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/Documents/clauden-backups/backup.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Documents/clauden-backups/backup-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl unload "$PLIST_FILE" 2>/dev/null
launchctl load "$PLIST_FILE"

echo "✅ Automatic daily backups configured!"
echo "📅 Backups will run daily at 3:00 AM"
echo "📁 Logs will be saved to: ~/Documents/clauden-backups/"
echo ""
echo "To check status: launchctl list | grep clauden"
echo "To disable: launchctl unload $PLIST_FILE"