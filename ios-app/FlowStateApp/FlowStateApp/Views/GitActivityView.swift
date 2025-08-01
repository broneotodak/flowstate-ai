import SwiftUI
import Foundation

struct GitActivityView: View {
    let gitActivities: [GitActivity]
    @State private var selectedActivity: GitActivity?
    @State private var showingAllActivities = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Git & GitHub Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if gitActivities.count > 3 {
                    Button("See All") {
                        showingAllActivities = true
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            
            // Git Activities
            if gitActivities.isEmpty {
                EmptyGitActivityView()
            } else {
                VStack(spacing: 8) {
                    ForEach(gitActivities.prefix(3)) { activity in
                        GitActivityRow(
                            activity: activity,
                            onTap: { selectedActivity = activity }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(item: $selectedActivity) { activity in
            GitActivityDetailView(activity: activity)
        }
        .sheet(isPresented: $showingAllActivities) {
            AllGitActivitiesView(activities: gitActivities)
        }
    }
}

struct AllGitActivitiesView: View {
    let activities: [GitActivity]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(activities) { activity in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: activity.type.systemImage)
                            .font(.title3)
                            .foregroundColor(Color(activity.type.color))
                        Text(activity.commitMessage)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.caption2)
                            Text(activity.repository)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.branch")
                                .font(.caption2)
                            Text(activity.branch)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(activity.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let additions = activity.additions, let deletions = activity.deletions {
                        HStack(spacing: 12) {
                            Text("+\(additions)")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("-\(deletions)")
                                .font(.caption)
                                .foregroundColor(.red)
                            if let filesChanged = activity.files_changed {
                                Text("\(filesChanged) files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("All Git Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GitActivityRow: View {
    let activity: GitActivity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Activity type icon
                Image(systemName: activity.type.systemImage)
                    .font(.title3)
                    .foregroundColor(Color(activity.type.color))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Commit message / activity description
                    Text(activity.commitMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Repository and branch
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.caption2)
                            Text(activity.repository)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.branch")
                                .font(.caption2)
                            Text(activity.branch)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Time ago
                        Text(activity.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Changes indicator
                if let additions = activity.additions, let deletions = activity.deletions {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text("+\(additions)")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("-\(deletions)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        
                        if let filesChanged = activity.files_changed {
                            Text("\(filesChanged) files")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyGitActivityView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.title)
                .foregroundColor(.gray)
            Text("No Git activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Your commits and GitHub activity will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct GitActivityDetailView: View {
    let activity: GitActivity
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Activity Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: activity.type.systemImage)
                                .font(.title2)
                                .foregroundColor(Color(activity.type.color))
                            Text(activity.type.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(activity.commitMessage)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Repository Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Repository Details")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(title: "Repository", value: activity.repository, icon: "folder")
                                InfoRow(title: "Branch", value: activity.branch, icon: "arrow.branch")
                                InfoRow(title: "Author", value: activity.author, icon: "person")
                                InfoRow(title: "Time", value: activity.timeAgo, icon: "clock")
                            }
                            Spacer()
                        }
                    }
                    
                    // Changes Info
                    if let additions = activity.additions, let deletions = activity.deletions {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Changes")
                                .font(.headline)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("+\(additions)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    Text("Additions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("-\(deletions)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                    Text("Deletions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let filesChanged = activity.files_changed {
                                    VStack {
                                        Text("\(filesChanged)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("Files")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Git Activity")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
                #endif
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(title + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}