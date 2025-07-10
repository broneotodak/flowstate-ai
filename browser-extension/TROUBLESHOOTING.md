# FlowState Browser Extension Troubleshooting

## Extension won't load/install

### 1. "Manifest file is missing or unreadable"
- Make sure you're selecting the `browser-extension` folder, not a parent folder
- The folder must contain `manifest.json` directly

### 2. "Could not load background script 'background.js'"
- Clear browser cache and reload
- Make sure Developer Mode is enabled in chrome://extensions/

### 3. Extension loads but shows errors in chrome://extensions/
- Click "Errors" to see details
- Common issues:
  - Missing service key (configure in popup)
  - Network errors (check internet connection)

## Extension loads but doesn't work

### 1. No activities showing
- Click the extension icon
- Enter your Supabase service key (get from `~/.flowstate/config`)
- Click "Save Settings"
- Click the refresh button (↻)

### 2. "Failed to fetch activities" in console
- Check if service key is correct
- Ensure your Supabase project is accessible
- Check browser console (F12) for detailed errors

### 3. Badge not updating
- Make sure "Auto-refresh" toggle is ON
- Activities only show from last 2 hours
- Check if you have any recent activities in FlowState

## How to reload the extension

1. Go to `chrome://extensions/`
2. Find "FlowState Status Viewer"
3. Click the refresh icon (🔄) on the extension card
4. Or toggle Developer mode off and on

## Check browser console for errors

1. Right-click the extension icon
2. Select "Inspect popup"
3. Go to Console tab
4. Look for any red error messages

## Complete reinstall

1. Go to `chrome://extensions/`
2. Remove the extension
3. Close all Chrome windows
4. Reopen Chrome
5. Go to `chrome://extensions/`
6. Enable Developer mode
7. Click "Load unpacked"
8. Select the `browser-extension` folder again