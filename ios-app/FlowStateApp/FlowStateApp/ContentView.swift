import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FlowStateViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                DashboardView(viewModel: viewModel)
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(0)
            
            // Activities Tab
            NavigationView {
                ActivitiesView(viewModel: viewModel)
            }
            .tabItem {
                Label("Activities", systemImage: "list.bullet.rectangle")
            }
            .tag(1)
            
            // Stats Tab
            NavigationView {
                StatsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.pie")
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            viewModel.startAutoRefresh()
        }
    }
}

// Dashboard View
struct DashboardView: View {
    @ObservedObject var viewModel: FlowStateViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Multiple Current Projects Card
                MultiProjectFlowView(projects: viewModel.currentProjects)
                
                // Git & GitHub Activity Section
                GitActivityView(gitActivities: viewModel.gitActivities)
                
                // Stats Overview
                HStack(spacing: 15) {
                    StatCard(
                        title: "Today",
                        value: "\(viewModel.todayActivities)",
                        icon: "calendar",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "This Week",
                        value: "\(viewModel.weekActivities)",
                        icon: "calendar.badge.clock",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // Active Machines
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Machines")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.activeMachines, id: \.self) { machine in
                        MachineRow(machine: machine)
                    }
                }
                
                // Recent Activities Preview
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recent Activities")
                            .font(.headline)
                        Spacer()
                        Button("See All") {
                            // Switch to activities tab
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    
                    ForEach(viewModel.activities.prefix(5)) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("FlowState")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// Current Project Card
struct CurrentProjectCard: View {
    let project: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "water.waves")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Current Flow")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(project)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Active now")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// Stat Card Component
struct StatCard: View {
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
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// Machine Row
struct MachineRow: View {
    let machine: String
    
    var machineIcon: String {
        if machine.contains("MacBook") { return "laptopcomputer" }
        if machine.contains("Chrome") { return "globe" }
        if machine.contains("claude") { return "cpu" }
        if machine.contains("Docker") { return "shippingbox" }
        return "desktopcomputer"
    }
    
    var body: some View {
        HStack {
            Image(systemName: machineIcon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(machine)
                .font(.subheadline)
            Spacer()
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// Activity Row
struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(activity.project_name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                Spacer()
                Text(activity.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(activity.activity_description)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "desktopcomputer")
                    .font(.caption2)
                Text(activity.machine ?? "Unknown")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
        .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}