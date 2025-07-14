#!/bin/bash

echo "🔧 Fixing Git Hooks for FlowState Integration"

# Create the correct post-commit hook that saves to claude_desktop_memory
cat > /Users/broneotodak/Projects/THR/.git/hooks/post-commit << 'EOF'
#!/bin/bash

# Save git commits to claude_desktop_memory for FlowState
if [ -z "$FLOWSTATE_SERVICE_KEY" ]; then
  exit 0
fi

# Get git info
COMMIT_MSG=$(git log -1 --pretty=%B | tr '\n' ' ' | sed 's/"/\\"/g')
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
BRANCH=$(git rev-parse --abbrev-ref HEAD)
AUTHOR=$(git log -1 --pretty=%an)
COMMIT_HASH=$(git rev-parse --short HEAD)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Create JSON payload for claude_desktop_memory table
JSON=$(cat <<JSON_EOF
{
  "user_id": "neo_todak",
  "memory_type": "activity",
  "category": "git_commit",
  "content": "Git commit in $REPO_NAME: $COMMIT_MSG",
  "metadata": {
    "activity_type": "git_commit",
    "project": "$REPO_NAME",
    "branch": "$BRANCH",
    "author": "$AUTHOR",
    "commit_hash": "$COMMIT_HASH",
    "machine": "$(hostname)",
    "source": "git_hook"
  },
  "importance": 5,
  "source": "git_hook"
}
JSON_EOF
)

# Send to Supabase claude_desktop_memory table
curl -s -X POST \
  "https://uzamamymfzhelvkwpvgt.supabase.co/rest/v1/claude_desktop_memory" \
  -H "apikey: $FLOWSTATE_SERVICE_KEY" \
  -H "Authorization: Bearer $FLOWSTATE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$JSON" > /tmp/git-hook-result.log 2>&1 &

exit 0
EOF

chmod +x /Users/broneotodak/Projects/THR/.git/hooks/post-commit

# Also add to CTK
cp /Users/broneotodak/Projects/THR/.git/hooks/post-commit /Users/broneotodak/Projects/claude-tools-kit/.git/hooks/post-commit
chmod +x /Users/broneotodak/Projects/claude-tools-kit/.git/hooks/post-commit

# Add to FlowState itself
cp /Users/broneotodak/Projects/THR/.git/hooks/post-commit /Users/broneotodak/Projects/flowstate-ai/.git/hooks/post-commit
chmod +x /Users/broneotodak/Projects/flowstate-ai/.git/hooks/post-commit

echo "✅ Git hooks updated to save to claude_desktop_memory table"
echo "📝 Activities will now appear in FlowState's Git & GitHub Activity section"
echo ""
echo "Testing with a commit..."