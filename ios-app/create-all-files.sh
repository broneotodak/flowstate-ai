#!/bin/bash

echo "Creating all remaining Swift files..."

# Create ActivitiesView.swift
cat > FlowStateApp/FlowStateApp/ActivitiesView.swift << 'EOF'
import SwiftUI

struct ActivitiesView: View {
    @ObservedObject var viewModel: FlowStateViewModel
    @State private var searchText = ""
    @State private var selectedProject: String? = nil
    
    var filteredActivities: [Activity] {
        viewModel.activities.filter { activity in
            let matchesSearch = searchText.isEmpty || 
                activity.activity_description.localizedCaseInsensitiveContains(searchText) ||
                (activity.project_name?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesProject = selectedProject == nil || activity.project_name == selectedProject
            
            return matchesSearch && matchesProject
        }
    }
    
    var uniqueProjects: [String] {
        Array(Set(viewModel.activities.compactMap { $0.project_name })).sorted()
    }
    
    var body: some View {
        VStack {
            // Project Filter
            if !uniqueProjects.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedProject == nil,
                            action: { selectedProject = nil }
                        )
                        
                        ForEach(uniqueProjects, id: \.self) { project in
                            FilterChip(
                                title: project,
                                isSelected: selectedProject == project,
                                action: { selectedProject = project }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 5)
            }
            
            // Activities List
            if filteredActivities.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No activities found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    if !searchText.isEmpty {
                        Text("Try adjusting your search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredActivities) { activity in
                    ActivityDetailRow(activity: activity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Activities")
        .searchable(text: $searchText, prompt: "Search activities")
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            if viewModel.isLoading && viewModel.activities.isEmpty {
                ProgressView("Loading activities...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct ActivityDetailRow: View {
    let activity: Activity
    
    var machineIcon: String {
        guard let machine = activity.machine else { return "desktopcomputer" }
        if machine.contains("MacBook") { return "laptopcomputer" }
        if machine.contains("Chrome") { return "globe" }
        if machine.contains("claude") { return "cpu" }
        if machine.contains("Docker") { return "shippingbox" }
        if machine.contains("GitHub") { return "chevron.left.forwardslash.chevron.right" }
        return "desktopcomputer"
    }
    
    var sourceColor: Color {
        guard let source = activity.source else { return .gray }
        switch source {
        case "git": return .orange
        case "cli", "claude-cli": return .blue
        case "browser_extension": return .green
        case "github_action": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.project_name ?? "Unknown Project")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text(activity.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Source badge
                if let source = activity.source {
                    Text(source.replacingOccurrences(of: "_", with: " "))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(sourceColor.opacity(0.2))
                        )
                        .foregroundColor(sourceColor)
                }
            }
            
            // Description
            Text(activity.activity_description)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Footer
            HStack {
                // Machine info
                HStack(spacing: 4) {
                    Image(systemName: machineIcon)
                        .font(.caption)
                    Text(activity.machine ?? "Unknown")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Duration if available
                if let duration = activity.duration_minutes, duration > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(duration)m")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
EOF

echo "✅ Created ActivitiesView.swift"

# Create StatsView.swift (simplified without Charts framework)
cat > FlowStateApp/FlowStateApp/StatsView.swift << 'EOF'
import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: FlowStateViewModel
    @State private var selectedTimeRange = TimeRange.today
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        
        var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Summary Cards
                HStack(spacing: 15) {
                    SummaryCard(
                        title: "Total Activities",
                        value: "\(getActivitiesCount(for: selectedTimeRange))",
                        icon: "list.bullet",
                        color: .blue
                    )
                    
                    SummaryCard(
                        title: "Active Projects",
                        value: "\(getProjectsCount(for: selectedTimeRange))",
                        icon: "folder",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // Project Distribution
                VStack(alignment: .leading, spacing: 10) {
                    Text("Project Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(getProjectDistribution(for: selectedTimeRange).prefix(5), id: \.project) { item in
                        ProjectStatRow(project: item.project, count: item.count, total: getActivitiesCount(for: selectedTimeRange))
                    }
                }
                
                // Machine Usage
                VStack(alignment: .leading, spacing: 10) {
                    Text("Machine Usage")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(getMachineUsage(for: selectedTimeRange), id: \.machine) { usage in
                        MachineUsageRow(usage: usage)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // Helper functions
    private func getFilteredActivities(for range: TimeRange) -> [Activity] {
        let calendar = Calendar.current
        let now = Date()
        
        return viewModel.activities.filter { activity in
            guard let date = ISO8601DateFormatter().date(from: activity.created_at) else { return false }
            let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return daysAgo < range.days
        }
    }
    
    private func getActivitiesCount(for range: TimeRange) -> Int {
        getFilteredActivities(for: range).count
    }
    
    private func getProjectsCount(for range: TimeRange) -> Int {
        Set(getFilteredActivities(for: range).compactMap { $0.project_name }).count
    }
    
    private func getProjectDistribution(for range: TimeRange) -> [(project: String, count: Int)] {
        let activities = getFilteredActivities(for: range)
        let grouped = Dictionary(grouping: activities) { $0.project_name ?? "Unknown" }
        return grouped.map { (project: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    private func getMachineUsage(for range: TimeRange) -> [(machine: String, count: Int, percentage: Double)] {
        let activities = getFilteredActivities(for: range)
        let total = activities.count
        let grouped = Dictionary(grouping: activities) { $0.machine ?? "Unknown" }
        
        return grouped.map { machine, activities in
            let count = activities.count
            let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0
            return (machine: machine, count: count, percentage: percentage)
        }
        .sorted { $0.count > $1.count }
    }
}

// Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// Project Stat Row
struct ProjectStatRow: View {
    let project: String
    let count: Int
    let total: Int
    
    var percentage: Double {
        total > 0 ? Double(count) / Double(total) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project)
                    .font(.subheadline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(Int(percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: geometry.size.width * (percentage / 100))
                    .animation(.easeInOut, value: percentage)
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// Machine Usage Row
struct MachineUsageRow: View {
    let usage: (machine: String, count: Int, percentage: Double)
    
    var machineIcon: String {
        if usage.machine.contains("MacBook") { return "laptopcomputer" }
        if usage.machine.contains("Chrome") { return "globe" }
        if usage.machine.contains("claude") { return "cpu" }
        if usage.machine.contains("Docker") { return "shippingbox" }
        return "desktopcomputer"
    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: machineIcon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(usage.machine)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(usage.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(usage.percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal)
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: geometry.size.width * (usage.percentage / 100))
                    .animation(.easeInOut, value: usage.percentage)
            }
            .frame(height: 4)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
        .padding(.horizontal)
    }
}
EOF

echo "✅ Created StatsView.swift"

# Create SettingsView.swift
cat > FlowStateApp/FlowStateApp/SettingsView.swift << 'EOF'
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
            
            // Auto Refresh
            Section {
                Toggle("Auto Refresh", isOn: $viewModel.autoRefresh)
                    .onChange(of: viewModel.autoRefresh) { newValue in
                        if newValue {
                            viewModel.startAutoRefresh()
                        } else {
                            viewModel.stopAutoRefresh()
                        }
                    }
                
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
                Text("Refresh Settings")
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
EOF

echo "✅ Created SettingsView.swift"
echo ""
echo "All files created! Now you can:"
echo "1. Go back to Xcode"
echo "2. The files should appear automatically"
echo "3. Press ⌘R to build and run"