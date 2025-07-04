# FlowState Browser Extension Installation Guide

## Quick Install Steps

### 1. Get the Extension Files
```bash
# Clone the repository
git clone https://github.com/broneotodak/flowstate-ai.git
cd flowstate-ai/browser-extension

# Or download just the browser-extension folder
```

### 2. Install in Chrome/Edge
1. Open Chrome or Edge
2. Navigate to `chrome://extensions/` (or `edge://extensions/`)
3. Enable **Developer mode** (toggle in top right)
4. Click **Load unpacked**
5. Select the `browser-extension` folder
6. Extension icon should appear in toolbar

### 3. Configure the Extension
1. Click the FlowState extension icon
2. Enter your Supabase service key
3. Click **Save Configuration**
4. Toggle **Enable Tracking** to ON

### 4. Get Your Service Key
```bash
# On your main machine, run:
cat ~/.flowstate/config

# Copy the FLOWSTATE_SERVICE_KEY value
```

## Alternative: Package for Easy Distribution

### Create a .crx file (on your main machine):
1. In Chrome, go to `chrome://extensions/`
2. Find FlowState Context Tracker
3. Click **Pack extension**
4. Browse to the extension directory
5. Click **Pack Extension**
6. This creates a `.crx` file

### Install .crx file (on other machines):
1. Open Chrome/Edge
2. Go to `chrome://extensions/`
3. Drag and drop the `.crx` file onto the page
4. Click **Add Extension**

## Firefox Installation
1. Open Firefox
2. Navigate to `about:debugging`
3. Click **This Firefox**
4. Click **Load Temporary Add-on**
5. Select `manifest.json` from the extension folder

## Verify Installation
- Extension badge shows project abbreviation (e.g., "FS" for FlowState)
- Check popup shows current context
- Visit flowstate.neotodak.com to see new machine listed

## Troubleshooting
- **No badge?** Check if tracking is enabled in popup
- **No service key?** Get it from `~/.flowstate/config` on main machine
- **Not tracking?** Ensure you're on GitHub/Claude.ai/localhost
- **Machine not showing?** Wait 5 minutes for first activity log