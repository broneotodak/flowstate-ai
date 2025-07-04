#!/bin/bash

# Install FlowState git hooks for automatic activity tracking

FLOWSTATE_DIR="$HOME/.flowstate"
HOOKS_DIR="$FLOWSTATE_DIR/git-hooks"

echo "🌊 Installing FlowState Git Hooks..."

# Create directories
mkdir -p "$HOOKS_DIR"

# Create the post-commit hook
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash

# FlowState Git Hook - Logs commits automatically

if [ -z "$FLOWSTATE_SERVICE_KEY" ]; then
  exit 0  # Silently exit if not configured
fi

# Get git info
COMMIT_MSG=$(git log -1 --pretty=%B)
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
BRANCH=$(git rev-parse --abbrev-ref HEAD)
AUTHOR=$(git log -1 --pretty=%an)
COMMIT_HASH=$(git rev-parse HEAD)

# Create JSON payload
JSON=$(cat <<JSON_EOF
{
  "user_id": "neo_todak",
  "activity_type": "git_commit",
  "activity_description": "$COMMIT_MSG",
  "project_name": "$REPO_NAME",
  "metadata": {
    "branch": "$BRANCH",
    "author": "$AUTHOR",
    "commit_hash": "$COMMIT_HASH",
    "machine_name": "$(hostname)",
    "source": "git_hook"
  }
}
JSON_EOF
)

# Send to Supabase
curl -s -X POST \
  "https://uzamamymfzhelvkwpvgt.supabase.co/rest/v1/activities" \
  -H "apikey: $FLOWSTATE_SERVICE_KEY" \
  -H "Authorization: Bearer $FLOWSTATE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$JSON" > /dev/null 2>&1 &

exit 0
EOF

# Create the post-push hook
cat > "$HOOKS_DIR/post-push" << 'EOF'
#!/bin/bash

# FlowState Git Hook - Logs pushes

if [ -z "$FLOWSTATE_SERVICE_KEY" ]; then
  exit 0
fi

REPO_NAME=$(basename $(git rev-parse --show-toplevel))
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE=$1
REMOTE_BRANCH=$2

JSON=$(cat <<JSON_EOF
{
  "user_id": "neo_todak",
  "activity_type": "git_push",
  "activity_description": "Pushed $BRANCH to $REMOTE",
  "project_name": "$REPO_NAME",
  "metadata": {
    "branch": "$BRANCH",
    "remote": "$REMOTE",
    "remote_branch": "$REMOTE_BRANCH",
    "machine_name": "$(hostname)",
    "source": "git_hook"
  }
}
JSON_EOF
)

curl -s -X POST \
  "https://uzamamymfzhelvkwpvgt.supabase.co/rest/v1/activities" \
  -H "apikey: $FLOWSTATE_SERVICE_KEY" \
  -H "Authorization: Bearer $FLOWSTATE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$JSON" > /dev/null 2>&1 &

exit 0
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/post-push"

# Create installation function
cat > "$FLOWSTATE_DIR/install-to-repo.sh" << 'EOF'
#!/bin/bash

# Install FlowState hooks to current repository

if [ ! -d .git ]; then
  echo "❌ Not a git repository"
  exit 1
fi

HOOKS_DIR="$HOME/.flowstate/git-hooks"

# Install hooks
cp "$HOOKS_DIR/post-commit" .git/hooks/
cp "$HOOKS_DIR/post-push" .git/hooks/

# Preserve existing hooks
if [ -f .git/hooks/post-commit.original ]; then
  cat .git/hooks/post-commit.original >> .git/hooks/post-commit
fi

echo "✅ FlowState hooks installed to $(basename $(pwd))"
EOF

chmod +x "$FLOWSTATE_DIR/install-to-repo.sh"

# Create global installer
cat > "$FLOWSTATE_DIR/install-global.sh" << 'EOF'
#!/bin/bash

# Install FlowState hooks globally using git templates

TEMPLATE_DIR="$HOME/.git-templates/hooks"
mkdir -p "$TEMPLATE_DIR"

cp "$HOME/.flowstate/git-hooks/"* "$TEMPLATE_DIR/"

# Configure git to use the template
git config --global init.templatedir "$HOME/.git-templates"

echo "✅ FlowState hooks installed globally"
echo "   New repositories will automatically have FlowState tracking"
echo "   For existing repos, run: git init"
EOF

chmod +x "$FLOWSTATE_DIR/install-global.sh"

echo "✅ FlowState git hooks created!"
echo ""
echo "To use them:"
echo "1. Set your service key:"
echo "   export FLOWSTATE_SERVICE_KEY='your-key'"
echo ""
echo "2. Install to current repo:"
echo "   cd /path/to/your/repo"
echo "   ~/.flowstate/install-to-repo.sh"
echo ""
echo "3. Or install globally for all new repos:"
echo "   ~/.flowstate/install-global.sh"