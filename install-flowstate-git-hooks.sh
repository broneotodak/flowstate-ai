#!/bin/bash

# FlowState Git Hooks Installer
# Automatically tracks your git activity to FlowState

echo "🌊 FlowState Git Hooks Installer"
echo "================================"

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Error: Not in a git repository. Run this from your project root."
    exit 1
fi

# Get project name from current directory or remote URL
PROJECT_NAME=$(basename "$PWD")
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null)
if [ ! -z "$REMOTE_URL" ]; then
    PROJECT_NAME=$(basename "$REMOTE_URL" .git)
fi

echo "📁 Installing hooks for project: $PROJECT_NAME"

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create the FlowState tracking script
cat > .git/hooks/flowstate-track.sh << 'EOF'
#!/bin/bash

# FlowState Activity Tracker
SUPABASE_URL="https://YOUR_PROJECT_ID.supabase.co"
SUPABASE_SERVICE_KEY="YOUR_SERVICE_KEY_HERE"
USER_ID="neo_todak"

# Function to log activity to FlowState
log_to_flowstate() {
    local activity_type=$1
    local description=$2
    local project_name=$3
    
    # Create JSON payload
    json_data=$(cat <<JSON
{
    "user_id": "$USER_ID",
    "activity_type": "$activity_type",
    "activity_description": "$description",
    "project_name": "$project_name",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
JSON
)
    
    # Send to Supabase
    curl -s -X POST \
        "$SUPABASE_URL/rest/v1/activities" \
        -H "apikey: $SUPABASE_SERVICE_KEY" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$json_data" > /dev/null 2>&1
    
    # Also update current context
    context_data=$(cat <<JSON
{
    "user_id": "$USER_ID",
    "project_name": "$project_name",
    "current_task": "$description",
    "current_phase": "Development",
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
JSON
)
    
    curl -s -X POST \
        "$SUPABASE_URL/rest/v1/current_context?on_conflict=user_id" \
        -H "apikey: $SUPABASE_SERVICE_KEY" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal,resolution=merge-duplicates" \
        -d "$context_data" > /dev/null 2>&1
}

# Export function for use in hooks
export -f log_to_flowstate
EOF

chmod +x .git/hooks/flowstate-track.sh

# Create post-commit hook
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
source .git/hooks/flowstate-track.sh

# Get commit info
COMMIT_MSG=$(git log -1 --pretty=%B)
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Log to FlowState
log_to_flowstate "git_commit" "Commit on $BRANCH: $COMMIT_MSG" "$PROJECT_NAME" &

exit 0
EOF

chmod +x .git/hooks/post-commit

# Create post-checkout hook (for branch switches)
cat > .git/hooks/post-checkout << 'EOF'
#!/bin/bash
source .git/hooks/flowstate-track.sh

# Only track branch checkouts, not file checkouts
if [ "$3" == "1" ]; then
    OLD_BRANCH=$(git name-rev --name-only $1)
    NEW_BRANCH=$(git name-rev --name-only $2)
    PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
    
    if [ "$OLD_BRANCH" != "$NEW_BRANCH" ]; then
        log_to_flowstate "git_checkout" "Switched from $OLD_BRANCH to $NEW_BRANCH" "$PROJECT_NAME" &
    fi
fi

exit 0
EOF

chmod +x .git/hooks/post-checkout

# Create pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
source .git/hooks/flowstate-track.sh

# Get push info
BRANCH=$(git rev-parse --abbrev-ref HEAD)
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
REMOTE=$1

log_to_flowstate "git_push" "Pushing $BRANCH to $REMOTE" "$PROJECT_NAME" &

exit 0
EOF

chmod +x .git/hooks/pre-push

echo "✅ Git hooks installed successfully!"
echo ""
echo "⚠️  IMPORTANT: Edit .git/hooks/flowstate-track.sh and replace:"
echo "   YOUR_SERVICE_KEY_HERE with your actual Supabase service key"
echo ""
echo "📊 The following activities will now be tracked automatically:"
echo "   - Git commits"
echo "   - Branch switches"
echo "   - Git pushes"
echo ""
echo "🔧 To install in other projects, run this script in each project directory."