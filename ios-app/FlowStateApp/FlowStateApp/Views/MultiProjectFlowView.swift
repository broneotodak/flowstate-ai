import SwiftUI
import Foundation

struct MultiProjectFlowView: View {
    let projects: [Project]
    @State private var selectedProject: Project?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "water.waves")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Current Flows")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if projects.count > 2 {
                    Button("See All") {
                        // Navigate to all projects view
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Project Cards
            if projects.isEmpty {
                EmptyProjectsView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(projects.prefix(3)) { project in
                            ProjectFlowCard(
                                project: project,
                                onTap: { selectedProject = project }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project)
        }
    }
}

struct ProjectFlowCard: View {
    let project: Project
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {                // Status indicator and activity count
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: project.status.systemImage)
                            .font(.caption)
                        Text(project.status.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(project.status == .active ? .green : .secondary)
                    
                    Spacer()
                    
                    Text("\(project.activityCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                
                // Project name
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Description or last activity
                if let description = project.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("Last activity \(project.lastActivity.timeAgoShort)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 160, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: project.color)?.opacity(0.1) ?? Color.blue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: project.color) ?? Color.blue, lineWidth: 1)
                    .opacity(0.3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyProjectsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.title)
                .foregroundColor(.gray)
            Text("No active projects")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Start working to see your flows here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct ProjectDetailView: View {
    let project: Project
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Project Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color(hex: project.color) ?? Color.blue)
                            .frame(width: 12, height: 12)
                        Text(project.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    if let description = project.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: project.status.systemImage)
                            Text(project.status.displayName)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Activities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(project.activityCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Last Activity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(project.lastActivity.timeAgoShort)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Project Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
            }
        }
    }
}