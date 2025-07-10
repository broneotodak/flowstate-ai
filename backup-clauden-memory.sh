#!/bin/bash

# ClaudeN Memory Backup Script
# Backs up your Claude Desktop memories to GitHub

# Configuration
GITHUB_REPO="broneotodak/clauden-memory"
GITHUB_TOKEN="${GITHUB_TOKEN:-}" # Set this in your environment

# Check if token is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN not set"
    echo "Run: export GITHUB_TOKEN='your-new-github-token'"
    exit 1
fi

# Source FlowState config for Supabase keys
source ~/.flowstate/config

# Create timestamp
TIMESTAMP=$(TZ="Asia/Jakarta" date +"%Y-%m-%d_%H%M")
FILENAME="clauden_backup_${TIMESTAMP}.json"

echo "🔄 Fetching memories from Supabase..."

# Fetch memories
MEMORIES=$(curl -s -X GET \
  "https://YOUR_PROJECT_ID.supabase.co/rest/v1/claude_desktop_memory?user_id=eq.neo_todak&order=created_at.desc&limit=1000" \
  -H "apikey: $FLOWSTATE_SERVICE_KEY" \
  -H "Authorization: Bearer $FLOWSTATE_SERVICE_KEY")

# Check if fetch was successful
if [ -z "$MEMORIES" ] || [ "$MEMORIES" = "[]" ]; then
    echo "❌ No memories found or fetch failed"
    exit 1
fi

# Count memories
TOTAL=$(echo "$MEMORIES" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))")
echo "✅ Found $TOTAL memories"

# Create backup structure
echo "📦 Creating backup structure..."
BACKUP=$(python3 << EOF
import json
import sys
from datetime import datetime

memories = $MEMORIES

# Group by category
categorized = {}
for mem in memories:
    cat = mem.get('category', 'uncategorized')
    if cat not in categorized:
        categorized[cat] = []
    categorized[cat].append(mem)

# Calculate stats
stats = {
    'total_memories': len(memories),
    'categories_count': len(categorized),
    'categories': sorted(categorized.keys()),
    'memories_per_category': {cat: len(mems) for cat, mems in categorized.items()},
    'important_memories': len([m for m in memories if m.get('importance', 0) >= 9]),
    'recent_memories': len([m for m in memories if (datetime.now() - datetime.fromisoformat(m['created_at'].replace('Z', '+00:00'))).days < 1])
}

backup = {
    'backup_metadata': {
        'created_at': datetime.now().isoformat(),
        'created_by': 'local-backup-script',
        'version': '1.0',
        'source': 'claude_desktop_memory',
        'user': 'neo_todak'
    },
    'statistics': stats,
    'memories_by_category': categorized,
    'all_memories': memories,
    'most_recent_memory': memories[0] if memories else None
}

print(json.dumps(backup, indent=2))
EOF
)

# Save local copy
LOCAL_BACKUP_DIR="$HOME/Documents/clauden-backups"
mkdir -p "$LOCAL_BACKUP_DIR"
echo "$BACKUP" > "$LOCAL_BACKUP_DIR/$FILENAME"
echo "💾 Local backup saved to: $LOCAL_BACKUP_DIR/$FILENAME"

# Upload to GitHub
echo "📤 Uploading to GitHub..."
CONTENT_BASE64=$(echo "$BACKUP" | base64)

UPLOAD_RESPONSE=$(curl -s -X PUT \
  "https://api.github.com/repos/$GITHUB_REPO/contents/backups/$FILENAME" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{
    \"message\": \"Automated backup - $TOTAL memories\",
    \"content\": \"$CONTENT_BASE64\",
    \"branch\": \"main\"
  }")

# Check if upload was successful
if echo "$UPLOAD_RESPONSE" | grep -q "content"; then
    echo "✅ Successfully uploaded to GitHub!"
    echo "📍 URL: https://github.com/$GITHUB_REPO/blob/main/backups/$FILENAME"
    
    # Send success notification
    curl -s -X POST https://ntfy.sh/neo_notifications \
      -H "Title: ClaudeN Backup Success" \
      -H "Priority: default" \
      -H "Tags: white_check_mark,floppy_disk" \
      -d "ClaudeN Memory Backup Complete
Total: $TOTAL memories
Backup saved to GitHub: backups/$FILENAME"
else
    echo "❌ GitHub upload failed!"
    echo "$UPLOAD_RESPONSE" | python3 -m json.tool
    
    # Send error notification
    curl -s -X POST https://ntfy.sh/neo_notifications \
      -H "Title: ClaudeN Backup FAILED" \
      -H "Priority: high" \
      -H "Tags: x,warning" \
      -d "ClaudeN Memory Backup Failed!
Check local backup at: $LOCAL_BACKUP_DIR/$FILENAME"
fi