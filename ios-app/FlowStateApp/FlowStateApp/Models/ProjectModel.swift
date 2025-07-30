import Foundation

// Project Model for Multiple Current Flows
struct Project: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let lastActivity: Date
    let activityCount: Int
    let status: ProjectStatus
    let color: String // Hex color for visual distinction
    
    enum ProjectStatus: String, Codable, CaseIterable {
        case active = "active"
        case paused = "paused"
        case completed = "completed"
        
        var displayName: String {
            switch self {
            case .active: return "Active"
            case .paused: return "Paused"
            case .completed: return "Completed"
            }
        }
        
        var systemImage: String {
            switch self {
            case .active: return "play.circle.fill"
            case .paused: return "pause.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
}

// Git Activity Model
struct GitActivity: Identifiable, Codable {
    let id: String
    let repository: String
    let branch: String
    let commitMessage: String
    let author: String
    let timestamp: Date
    let type: GitActivityType
    let additions: Int?
    let deletions: Int?
    let files_changed: Int?
    
    enum GitActivityType: String, Codable, CaseIterable {
        case commit = "commit"
        case push = "push"
        case pull_request = "pull_request"
        case merge = "merge"
        case branch_create = "branch_create"
        case branch_delete = "branch_delete"
        
        var displayName: String {
            switch self {
            case .commit: return "Commit"
            case .push: return "Push"
            case .pull_request: return "Pull Request"
            case .merge: return "Merge"
            case .branch_create: return "Branch Created"
            case .branch_delete: return "Branch Deleted"
            }
        }
        
        var systemImage: String {
            switch self {
            case .commit: return "checkmark.circle"
            case .push: return "arrow.up.circle"
            case .pull_request: return "arrow.triangle.merge"
            case .merge: return "arrow.triangle.branch"
            case .branch_create: return "plus.circle"
            case .branch_delete: return "minus.circle"
            }
        }
        
        var color: String {
            switch self {
            case .commit: return "blue"
            case .push: return "green"
            case .pull_request: return "purple"
            case .merge: return "orange"
            case .branch_create: return "mint"
            case .branch_delete: return "red"
            }
        }
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(days)d ago"
    }
}

// GitHub Repository Model
struct GitHubRepository: Identifiable, Codable {
    let id: String
    let name: String
    let fullName: String
    let description: String?
    let isPrivate: Bool
    let language: String?
    let stars: Int
    let forks: Int
    let lastUpdated: Date
    let url: String
    
    // Custom coding keys to handle the 'private' field from JSON
    enum CodingKeys: String, CodingKey {
        case id, name, fullName, description, language, stars, forks, lastUpdated, url
        case isPrivate = "private"
    }
}