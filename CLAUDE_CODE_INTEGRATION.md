# Claude Code + FlowState Integration Guide

## The Problem
Claude Code doesn't automatically log activities to FlowState because:
- It's a standalone CLI tool without FlowState awareness
- It saves memories to `claude_desktop_memory` but not `activity_log`
- There's no automatic integration between Claude Code and FlowState

## Current Activity Tracking

### What Gets Tracked Automatically:
1. **Browser Extension** - Tracks GitHub browsing
2. **Git Commits** - When git hooks are configured
3. **System Monitor** - Basic file monitoring (if daemon is running)

### What Doesn't Get Tracked:
1. **Claude Code Sessions** ❌
2. **Cursor AI Sessions** ❌ (unless manually logged)
3. **VSCode Sessions** ❌ (unless extension installed)

## Manual Logging Solution

### Quick Command: `claude-log`
I've created a quick logging command in `~/.flowstate/claude-log`:

```bash
# Log current work (auto-detects project)
claude-log development "Working on new feature"

# Different activity types
claude-log debugging "Fixing database connection issue"
claude-log research "Investigating pgvector performance"
claude-log refactoring "Cleaning up authentication code"
```

### Using the Manual Logger
```bash
# From project directory
node manual-activity-logger.js "FlowState AI" "development" "Building new dashboard features"

# Quick test
node manual-activity-logger.js
```

## Proposed Automatic Solutions

### 1. Claude Code Wrapper Script
Create a wrapper that logs before/after Claude Code sessions:
```bash
#!/bin/bash
# flowstate-claude script
claude-log ai_conversation "Starting Claude Code session"
claude-code "$@"
claude-log ai_conversation "Ended Claude Code session"
```

### 2. File Watcher Integration
Run a watcher that detects file changes and logs them:
```javascript
// Watch for file changes in current project
const watcher = require('./file-activity-watcher');
watcher.start('/path/to/project');
```

### 3. VSCode/Cursor Extension
Create extensions that automatically log:
- File opens/edits
- Terminal commands
- Debug sessions
- Git operations

## Why This Matters

Without activity logging, FlowState can't show:
- ⏰ Time spent on projects
- 📊 Development patterns
- 🔄 Context switching
- 📈 Productivity insights

## Temporary Workaround

Until automatic logging is implemented, remember to manually log significant activities:

```bash
# Start of session
claude-log development "Starting work on FlowState dashboard"

# Major milestones
claude-log feature "Implemented activity filtering"

# End of session
claude-log development "Completed dashboard redesign"
```

## Future Integration Ideas

1. **Claude Code Plugin System** - Allow Claude Code to load FlowState plugin
2. **Shell Integration** - Detect Claude Code usage via shell hooks
3. **Proxy Logger** - Intercept Claude Code operations
4. **Memory Bridge** - Sync `claude_desktop_memory` to `activity_log`

## Quick Setup

1. Ensure FlowState config is loaded:
```bash
source ~/.flowstate/config
```

2. Use the quick logger:
```bash
claude-log development "Your activity description"
```

3. Check the dashboard:
Visit https://flowstate.neotodak.com to see your logged activities

---

**Note**: This is a temporary solution. A proper Claude Code + FlowState integration would require changes to Claude Code itself or a more sophisticated wrapper system.