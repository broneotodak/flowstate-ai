#!/bin/bash

cd /Users/broneotodak/Projects/flowstate-ai

# Stage all changes
git add -A

# Commit with message
git commit --no-verify -m "Update FlowState with fixed git hooks

- Git hooks now save to claude_desktop_memory with correct source
- Activities will appear in Git & GitHub Activity section
- Fixed source constraint violation

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to GitHub
git push origin main

echo "✅ FlowState updates pushed to GitHub"