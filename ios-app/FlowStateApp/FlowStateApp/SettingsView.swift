import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: FlowStateViewModel
    @State private var showingServiceKeyInput = false
    @State private var tempServiceKey = ""
    @State private var isTestingConnection = false
    @State private var connectionTestResult: String?
    @State private var showingAbout = false
    
    var body: some View {
        Form {
            // API Configuration
            Section {
                HStack {
                    Text("Service Key")
                    Spacer()
                    if viewModel.serviceKey.isEmpty {
                        Text("Not configured")
                            .foregroundColor(.red)
                    } else {
                        Text("Configured")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    tempServiceKey = viewModel.serviceKey
                    showingServiceKeyInput = true
                }
                
                if !viewModel.serviceKey.isEmpty {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(isTestingConnection)
                    
                    if let result = connectionTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("Success") ? .green : .red)
                    }
                }
            } header: {
                Text("API Configuration")
            } footer: {
                Text("Get your service key from ~/.flowstate/config on your main machine")
                    .font(.caption)
            }
            
            // Auto Refresh & Notifications
            Section {
                Toggle("Auto Refresh", isOn: Binding(
                    get: { viewModel.autoRefresh },
                    set: { newValue in
                        viewModel.autoRefresh = newValue
                        if newValue {
                            viewModel.startAutoRefresh()
                        } else {
                            viewModel.stopAutoRefresh()
                        }
                    }
                ))
                
                if viewModel.autoRefresh {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                        Text("Refreshes every 30 seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Auto Refresh")
            }
            
            Section {
                Toggle("Memory Notifications", isOn: Binding(
                    get: { viewModel.notificationsEnabled },
                    set: { _ in viewModel.toggleNotifications() }
                ))
                
                // Show actual notification permission status
                HStack {
                    Image(systemName: viewModel.notificationManager.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(viewModel.notificationManager.isAuthorized ? .green : .orange)
                    Text(viewModel.notificationManager.isAuthorized ? "Permission Granted" : "Permission Required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.notificationsEnabled {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.secondary)
                        Text("Alerts when flow state memory updates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Test Notification") {
                        viewModel.notificationManager.sendTestNotification()
                    }
                    .foregroundColor(.blue)
                }
            } header: {
                Text("Notifications")
            } footer: {
                if viewModel.notificationsEnabled {
                    Text("Get notified when new activities are detected or projects change")
                        .font(.caption)
                } else {
                    Text("Enable to get notified when new activities are detected or projects change")
                        .font(.caption)
                }
            }
            
            // GitHub Integration
            Section {
                NavigationLink("GitHub Integration") {
                    GitHubSettingsView(viewModel: viewModel)
                }
                
                HStack {
                    Image(systemName: viewModel.isGitHubConnected ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(viewModel.isGitHubConnected ? .green : .red)
                    Text(viewModel.isGitHubConnected ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Git Activity")
            } footer: {
                Text("Connect your GitHub account to see real commit activity in the dashboard")
                    .font(.caption)
            }
            
            // Data Management
            Section {
                Button("Refresh Now") {
                    Task {
                        await viewModel.refresh()
                    }
                }
                
                HStack {
                    Text("Activities Loaded")
                    Spacer()
                    Text("\(viewModel.activities.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Active Machines")
                    Spacer()
                    Text("\(viewModel.activeMachines.count)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Data")
            }
            
            // About
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Button("About FlowState") {
                    showingAbout = true
                }
                
                Link("View Dashboard", destination: URL(string: "https://flowstate.neotodak.com")!)
                
                Link("GitHub Repository", destination: URL(string: "https://github.com/broneotodak/flowstate-ai")!)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingServiceKeyInput) {
            ServiceKeyInputView(
                serviceKey: $tempServiceKey,
                onSave: {
                    viewModel.serviceKey = tempServiceKey
                    viewModel.saveServiceKey()
                    showingServiceKeyInput = false
                    connectionTestResult = nil
                },
                onCancel: {
                    showingServiceKeyInput = false
                }
            )
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        Task {
            let success = await viewModel.testConnection()
            
            await MainActor.run {
                connectionTestResult = success ? "✓ Connection successful!" : "✗ Connection failed"
                isTestingConnection = false
            }
        }
    }
}

// Service Key Input View
struct ServiceKeyInputView: View {
    @Binding var serviceKey: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter your Supabase service key")
                    .font(.headline)
                    .padding(.top)
                
                Text("You can find this in ~/.flowstate/config on your main machine")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextEditor(text: $serviceKey)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 100)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Service Key")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(serviceKey.isEmpty)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// About View
struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Icon
                    Image(systemName: "water.waves")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    Text("FlowState")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your coding flow across all devices")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Real-time Tracking",
                            description: "Monitor your coding activities across all machines"
                        )
                        
                        FeatureRow(
                            icon: "desktopcomputer",
                            title: "Multi-device Support",
                            description: "Works with Git, CLI tools, browser extensions, and more"
                        )
                        
                        FeatureRow(
                            icon: "chart.pie",
                            title: "Detailed Analytics",
                            description: "Visualize your productivity patterns and project focus"
                        )
                        
                        FeatureRow(
                            icon: "lock.shield",
                            title: "Privacy First",
                            description: "Your data stays in your own Supabase instance"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Text("Made with ❤️ by Neo Todak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                }
            }
            .navigationTitle("About")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Dismiss handled by sheet
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
