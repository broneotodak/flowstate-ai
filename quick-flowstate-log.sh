#!/bin/bash
# Quick FlowState logger with immediate sync

if [ -z "$1" ]; then
  echo "Usage: ./quick-flowstate-log.sh \"description of activity\""
  exit 1
fi

# Save to memory
./claude-log "$1"

# Immediately sync to dashboard
echo "Syncing to dashboard..."
node memory-to-activity-sync.js --once --project flowstate

echo "✅ Activity logged and synced!"