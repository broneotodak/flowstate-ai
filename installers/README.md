# FlowState Browser Extension Installers

## Quick Install

### Windows
1. Download `FlowState-Extension-Installer-Windows.bat`
2. Right-click → Run as Administrator
3. Follow the on-screen instructions

### Mac
1. Download `FlowState-Extension-Installer-Mac.sh`
2. Open Terminal in the download folder
3. Run: `./FlowState-Extension-Installer-Mac.sh`
4. Follow the on-screen instructions

### Manual Install
1. Download `flowstate-browser-extension.zip`
2. Extract to a folder
3. Open Chrome/Edge → Extensions → Developer mode ON
4. Click "Load unpacked" → Select the extracted folder

## After Installation
1. Click the FlowState icon in your browser toolbar
2. Enter your service key (get it from `~/.flowstate/config`)
3. Enable tracking
4. The extension will now track your browser activity

## What Gets Tracked
- GitHub repository visits
- Claude.ai conversations
- Project detection from page content
- Active tab context every 30 seconds
- Activities logged every 5 minutes

## Privacy
- All data stays in your personal Supabase database
- No third-party tracking
- Only tracks specified domains (GitHub, Claude.ai, localhost)
- You control what gets tracked via the extension popup