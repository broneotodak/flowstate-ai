#!/bin/bash

# Script to start new Claude session in a new terminal tab

# Create a temporary script that will run in the new terminal
cat > /tmp/claude-flowstate-browser-extension.sh << 'EOF'
#!/bin/bash

# Navigate to flowstate-ai directory
cd /Users/broneotodak/Projects/flowstate-ai

# Start Claude and send Enter to select first option
echo "Starting Claude Code..."
claude

# Note: The prompt will be ready for you to type about checking the browser extension
echo "Ready to check FlowState browser extension..."
EOF

chmod +x /tmp/claude-flowstate-browser-extension.sh

# Open new terminal tab with Homebrew profile and run the script
osascript -e 'tell application "Terminal"
    activate
    tell application "System Events" to keystroke "t" using command down
    delay 1
    do script "source ~/.flowstate/config && /tmp/claude-flowstate-browser-extension.sh" in front window
end tell'

echo "✅ Opening new Terminal tab with Claude..."
echo "📝 When Claude starts, type:"
echo "   'Check the browser extension setup in the flowstate-ai project'"