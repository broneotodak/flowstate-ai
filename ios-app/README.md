# FlowState iOS App

A native iOS app for viewing your FlowState coding activities on the go!

## Features

- 📊 **Real-time Dashboard** - See your current project and recent activities
- 📈 **Statistics** - Visualize your coding patterns with beautiful charts
- 🔍 **Activity History** - Browse and search through all your activities
- 🔄 **Auto-refresh** - Stays up to date with your latest flow
- 🌗 **Dark Mode Support** - Automatic light/dark theme switching

## Screenshots

### Dashboard
- Current project display
- Today/Week activity counts
- Active machines list
- Recent activities preview

### Activities
- Full activity timeline
- Search and filter by project
- Machine and source indicators
- Time-based grouping

### Statistics
- Project distribution charts
- Activity timeline graphs
- Machine usage breakdown
- Most active hours visualization

### Settings
- Service key configuration
- Auto-refresh toggle
- Connection testing
- About section

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. **Open in Xcode**
   ```bash
   cd ios-app
   open FlowStateApp.xcodeproj
   ```

2. **Configure Signing**
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your development team

3. **Build and Run**
   - Select your target device/simulator
   - Press Cmd+R to build and run

## Configuration

1. **Get your service key**:
   ```bash
   cat ~/.flowstate/config | grep FLOWSTATE_SERVICE_KEY
   ```

2. **In the app**:
   - Go to Settings tab
   - Tap "Service Key"
   - Paste your key
   - Tap "Save"

## Architecture

- **SwiftUI** - Modern declarative UI
- **Combine** - Reactive data flow
- **Charts** - Native iOS charts framework
- **URLSession** - Network requests to Supabase

## File Structure

```
FlowStateApp/
├── FlowStateApp.swift      # App entry point
├── ContentView.swift       # Main tab view
├── FlowStateViewModel.swift # Data model and API
├── ActivitiesView.swift    # Activities list
├── StatsView.swift         # Statistics charts
└── SettingsView.swift      # App settings
```

## API Integration

The app connects directly to your Supabase instance using the REST API:
- Fetches activities from `flowstate_activities` view
- Updates every 30 seconds when auto-refresh is enabled
- Caches data for offline viewing

## Future Enhancements

- [ ] Push notifications for milestones
- [ ] Widget for home screen
- [ ] Apple Watch companion app
- [ ] iPad optimized layout
- [ ] Activity logging from iOS
- [ ] Shortcuts integration

## Development

To contribute:
1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Test on multiple devices
5. Submit a pull request

## License

Same as FlowState main project