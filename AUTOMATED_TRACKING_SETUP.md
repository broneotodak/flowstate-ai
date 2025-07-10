# 🌊 FlowState Automated Tracking Setup Guide

Transform FlowState into a truly smart context-aware system that automatically tracks what you're working on without any manual input.

## 🎯 Available Tracking Methods

### 1. Git Hooks (Local) - **Easiest to Start**
Automatically tracks when you commit, push, or switch branches.

**Setup:**
```bash
# In each project directory:
cd /path/to/your/project
bash /Users/broneotodak/Projects/flowstate-ai-github/install-flowstate-git-hooks.sh

# Edit the service key:
nano .git/hooks/flowstate-track.sh
# Replace YOUR_SERVICE_KEY_HERE with your actual key
```

**What it tracks:**
- Git commits with messages
- Branch switches
- Push events
- Automatically updates project context

### 2. GitHub Webhooks (Cloud) - **Most Comprehensive**
Real-time tracking of all GitHub activity.

**Setup:**
1. Deploy the Edge Function:
```bash
cd /Users/broneotodak/Projects/flowstate-ai-github
supabase functions deploy github-webhook --no-verify-jwt
```

2. Add webhook to your GitHub repos:
   - Go to Settings → Webhooks
   - Add webhook URL: `https://YOUR_PROJECT_ID.supabase.co/functions/v1/github-webhook`
   - Select events: Push, Pull Request, Issues
   - Content type: application/json

**What it tracks:**
- All commits and pushes
- Pull request activities
- Issue management
- Repository creation/deletion
- Generates embeddings for AI-related commits

### 3. Browser Extension - **Most Intelligent**
Detects what project you're working on based on open tabs.

**Setup:**
1. Open Chrome/Edge
2. Go to `chrome://extensions/`
3. Enable "Developer mode"
4. Click "Load unpacked"
5. Select `/Users/broneotodak/Projects/flowstate-ai-github/browser-extension`
6. Click the extension icon and enter your service key

**What it tracks:**
- Active GitHub repositories
- Claude.ai conversations (detects FlowState mentions)
- Local development servers
- Updates context every 30 seconds
- Logs activities every 5 minutes

### 4. Supabase Memory Tracker (Coming Soon)
Tracks AI tool usage through pgvector memory.

**Features:**
- Monitors Claude/ChatGPT conversations
- Extracts project context from AI interactions
- Links conversations to specific tasks

## 🚀 Quick Start Recommendations

### For Immediate Impact:
1. **Install Git Hooks** on your FlowState project (2 minutes)
2. **Load Browser Extension** (1 minute)
3. Your context will start updating automatically!

### For Complete Coverage:
1. Set up GitHub webhooks on all active repos
2. Keep browser extension running
3. Git hooks as backup for offline work

## 🔧 Testing Your Setup

### Check if tracking is working:
1. Make a commit in your project
2. Open your FlowState dashboard
3. Check "Current Context" - it should show:
   - Correct project name
   - Recent timestamp (within minutes)
   - Your last commit message as task

### View tracked activities:
```sql
-- In Supabase SQL Editor
SELECT * FROM activities 
WHERE user_id = 'neo_todak' 
ORDER BY created_at DESC 
LIMIT 20;
```

## 📊 How It All Works Together

```
Your Work → Multiple Detection Points → FlowState Context
    ↓               ↓                         ↓
Git Commits → Git Hooks        ────→ Activities Table
GitHub Push → Webhooks         ────→ Current Context
Browser Tabs → Extension       ────→ AI Embeddings
AI Chat → Memory Tracker       ────→ Smart Insights
```

## 🎨 Customization

### Add More Project Patterns
Edit `browser-extension/background.js`:
```javascript
const PROJECT_PATTERNS = {
  'YourProject': [
    /your-project/i,
    /specific-keyword/i
  ]
};
```

### Track More Git Events
Edit `.git/hooks/post-merge` for merge tracking
Edit `.git/hooks/pre-commit` for commit preparation

## 🐛 Troubleshooting

**Context not updating?**
- Check service key is correct
- Verify activities are being logged
- Check browser extension is enabled

**Wrong project detected?**
- Browser extension uses pattern matching
- Add more specific patterns for your projects
- Check confidence scores in extension popup

**Git hooks not working?**
- Ensure hooks have execute permission: `chmod +x .git/hooks/*`
- Check service key in flowstate-track.sh
- Look for curl errors in terminal

## 🎯 End Result

With all systems running:
- Make a commit → Context updates in seconds
- Open a GitHub PR → FlowState knows immediately  
- Start coding in VS Code → Browser tabs detect project
- Chat with Claude → Context reflects AI work

No more manual tracking. FlowState just knows what you're doing! 🚀