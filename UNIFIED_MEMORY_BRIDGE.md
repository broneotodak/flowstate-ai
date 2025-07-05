# FlowState Unified Memory Bridge

## Overview
The Memory Bridge automatically syncs ALL AI tool interactions from pgvector memory tables to FlowState's activity_log, ensuring every AI session appears in your dashboard.

## How It Works

### Memory Sources
1. **claude_desktop_memory** - All Claude Desktop, Claude Code, Cursor, VSCode interactions
2. **context_embeddings** - FlowState-specific embeddings and activities

### Sync Process
```
AI Tool → Saves to Memory → Bridge Detects → Creates Activity → Shows in Dashboard
```

## Features

### Automatic Project Detection
- Extracts project names from memory content
- Normalizes FlowState variants to "FlowState AI"
- Maps tools to readable names (e.g., "claude_desktop" → "Claude Desktop")

### Intelligent Activity Descriptions
Memory types are converted to meaningful descriptions:
- `conversation_summary` → "AI conversation session"
- `technical_solution` → "Implemented technical solution"
- `project_milestone` → "Reached project milestone"
- And more...

### Continuous Monitoring
- Checks for new memories every 30 seconds
- Resumes from last sync point (no duplicates)
- Saves checkpoint markers for reliability

## Installation

### 1. One-Time Setup
```bash
# Run the bridge script once to catch up
cd ~/Projects/flowstate-ai
source ~/.flowstate/config
node memory-to-flowstate-bridge.js --once
```

### 2. Start the Daemon
```bash
# Start continuous monitoring
~/.flowstate/memory-bridge-daemon.js start

# Check status
~/.flowstate/memory-bridge-daemon.js status

# View logs
tail -f ~/.flowstate/memory-bridge.log
```

### 3. Start All Services
```bash
# Start everything at once
~/.flowstate/start-all.sh
```

## What Gets Synced

### From claude_desktop_memory:
- ✅ All Claude Desktop conversations
- ✅ Claude Code sessions
- ✅ Cursor AI activities
- ✅ VSCode + Claude interactions
- ✅ Any tool that saves to this table

### From context_embeddings:
- ✅ Non-activity embeddings (conversations, features, etc.)
- ❌ Activity type (already in activity_log)
- ❌ System/documentation types

## Benefits

1. **Complete Activity History** - Never miss an AI interaction
2. **Multi-Tool Support** - Works with ALL AI tools automatically
3. **Zero Configuration** - Just start the daemon
4. **Project Organization** - Auto-detects and normalizes projects
5. **Real-Time Updates** - See activities within 30 seconds

## Troubleshooting

### Activities Not Showing?
1. Check daemon is running: `~/.flowstate/memory-bridge-daemon.js status`
2. Check logs: `tail ~/.flowstate/memory-bridge.log`
3. Verify memories exist: Check claude_desktop_memory table

### Wrong Project Names?
The bridge tries to extract project names from:
1. Memory metadata
2. Content patterns (project:, working on, etc.)
3. Known project names

### Too Many "Unknown Project"?
This happens when memories don't contain clear project indicators. The AI tool should include project context when saving memories.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   AI Tools      │     │   AI Tools      │
│ (Claude, Cursor)│     │ (VSCode, etc)   │
└────────┬────────┘     └────────┬────────┘
         │                       │
         v                       v
┌─────────────────────────────────────────┐
│        claude_desktop_memory            │
│         (pgvector storage)              │
└────────────────┬───────────────────────┘
                 │
                 v
┌─────────────────────────────────────────┐
│      Memory to FlowState Bridge         │
│        (Runs every 30 seconds)          │
└────────────────┬───────────────────────┘
                 │
                 v
┌─────────────────────────────────────────┐
│           activity_log                  │
│      (FlowState activities)             │
└────────────────┬───────────────────────┘
                 │
                 v
┌─────────────────────────────────────────┐
│        FlowState Dashboard              │
│    (flowstate.neotodak.com)            │
└─────────────────────────────────────────┘
```

## Future Improvements

1. **Webhook Support** - Instant sync instead of polling
2. **Better Project Detection** - ML-based project extraction
3. **Activity Grouping** - Combine related memories into sessions
4. **Custom Mappings** - User-defined project name mappings
5. **Performance Metrics** - Track sync performance and delays

---

With this bridge running, you'll never miss tracking an AI interaction again. Every Claude conversation, every Cursor session, every AI-assisted coding activity will automatically appear in your FlowState dashboard!