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
                .frame(height: 40)
            }
            
            // Activities List
            if filteredActivities.isEmpty {
                Spacer()
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
                Spacer()
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
                VStack {
                    Spacer()
                    ProgressView("Loading activities...")
                        .padding()
                    Spacer()
                }
                .background(Color.gray.opacity(0.1))
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
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}
