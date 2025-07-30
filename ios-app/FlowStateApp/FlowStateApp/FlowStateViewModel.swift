import Foundation
import Combine

// Metadata Model
struct ActivityMetadata: Codable {
    let tool: String?
    let source: String?
    let machine: String?
    let memory_id: Int?
    let timestamp: String?
}

// Activity Model
struct Activity: Identifiable, Codable {
    let id: String
    let user_id: String
    let activity_type: String
    let activity_description: String
    let project_name: String?
    let created_at: String
    let metadata: ActivityMetadata?
    let has_embedding: Bool?
    
    // Computed properties for convenience
    var machine: String? {
        return metadata?.machine
    }
    
    var source: String? {
        return metadata?.source
    }
    
    var timeAgo: String {
        // First try with custom formatter for the format we're getting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        var date = dateFormatter.date(from: created_at)
        
        // Try without microseconds
        if date == nil {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            date = dateFormatter.date(from: created_at)
        }
        
        // Fall back to ISO8601 formatter
        if date == nil {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = formatter.date(from: created_at)
            
            if date == nil {
                formatter.formatOptions = [.withInternetDateTime]
                date = formatter.date(from: created_at)
            }
        }
        
        guard let validDate = date else { return "Unknown" }
        
        let interval = Date().timeIntervalSince(validDate)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(days)d ago"
    }
}

// Main ViewModel
@MainActor
class FlowStateViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var currentProject: String?
    @Published var activeMachines: [String] = []
    @Published var todayActivities = 0
    @Published var weekActivities = 0
    @Published var isLoading = false
    @Published var error: String?
    
    // Settings
    @Published var serviceKey: String = UserDefaults.standard.string(forKey: "serviceKey") ?? ""
    @Published var autoRefresh = true
    @Published var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    
    // Notification Manager
    let notificationManager = NotificationManager()
    
    private let supabaseURL = "https://uzamamymfzhelvkwpvgt.supabase.co"
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastActivityCount = 0
    
    init() {
        Task {
            await refresh()
        }
    }
    
    func startAutoRefresh() {
        guard autoRefresh else { return }
        
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.refresh()
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func refresh() async {
        await refreshEnhanced()
    }
    
    private func fetchActivities() async throws -> [Activity] {
        let twoHoursAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-2 * 60 * 60))
        
        var components = URLComponents(string: "\(supabaseURL)/rest/v1/flowstate_activities")!
        components.queryItems = [
            URLQueryItem(name: "created_at", value: "gte.\(twoHoursAgo)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(serviceKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("FlowState API Response: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("FlowState API Error Response: \(String(data: data, encoding: .utf8) ?? "Unknown")")
            throw URLError(.badServerResponse)
        }
        
        // Log the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("FlowState API Data (first 500 chars): \(String(jsonString.prefix(500)))")
        }
        
        let activities = try JSONDecoder().decode([Activity].self, from: data)
        print("FlowState: Decoded \(activities.count) activities")
        return activities
    }
    
    private func calculateStats(from activities: [Activity]) {
        let calendar = Calendar.current
        let now = Date()
        
        // Helper function to parse dates
        func parseDate(_ dateString: String) -> Date? {
            // First try with custom formatter for the format we're getting
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Try without microseconds
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Fall back to ISO8601 formatter
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateString)
        }
        
        // Today's activities
        todayActivities = activities.filter { activity in
            guard let date = parseDate(activity.created_at) else { 
                print("Failed to parse date: \(activity.created_at)")
                return false 
            }
            let isToday = calendar.isDateInToday(date)
            if isToday {
                print("Activity from today: \(activity.activity_description)")
            }
            return isToday
        }.count
        
        // This week's activities
        weekActivities = activities.filter { activity in
            guard let date = parseDate(activity.created_at) else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        }.count
        
        print("Stats - Today: \(todayActivities), This week: \(weekActivities)")
    }
    
    func saveServiceKey() {
        UserDefaults.standard.set(serviceKey, forKey: "serviceKey")
        Task {
            await refresh()
        }
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        if notificationsEnabled {
            Task {
                await notificationManager.requestPermission()
            }
        } else {
            notificationManager.clearBadge()
        }
    }
    
    func testConnection() async -> Bool {
        guard !serviceKey.isEmpty else { return false }
        
        var components = URLComponents(string: "\(supabaseURL)/rest/v1/flowstate_activities")!
        components.queryItems = [URLQueryItem(name: "limit", value: "1")]
        
        var request = URLRequest(url: components.url!)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(serviceKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}    // MARK: - Enhanced Properties for Multiple Projects
    @Published var currentProjects: [Project] = []
    @Published var gitActivities: [GitActivity] = []
    @Published var githubRepositories: [GitHubRepository] = []
    
    // MARK: - Enhanced Project Management
    private func updateCurrentProjects(from activities: [Activity]) {
        // Group activities by project and calculate stats
        let projectGroups = Dictionary(grouping: activities) { $0.project_name ?? "Unknown" }
        
        var projects: [Project] = []
        
        for (projectName, projectActivities) in projectGroups {
            guard projectName != "Unknown" else { continue }
            
            let lastActivity = projectActivities.compactMap { activity in
                parseActivityDate(activity.created_at)
            }.max() ?? Date()
            
            let project = Project(
                id: UUID().uuidString,
                name: projectName,
                description: generateProjectDescription(from: projectActivities),
                lastActivity: lastActivity,
                activityCount: projectActivities.count,
                status: determineProjectStatus(from: projectActivities, lastActivity: lastActivity),
                color: Color.randomProjectColor()
            )
            
            projects.append(project)
        }
        
        // Sort by most recent activity and take top active projects
        self.currentProjects = projects
            .sorted { $0.lastActivity > $1.lastActivity }
            .prefix(5)
            .map { $0 }
    }
    
    private func generateProjectDescription(from activities: [Activity]) -> String? {
        // Generate smart description based on activity types
        let activityTypes = activities.map { $0.activity_type }
        let uniqueTypes = Set(activityTypes)
        
        if uniqueTypes.contains("git_commit") && uniqueTypes.contains("code_edit") {
            return "Active development with commits"
        } else if uniqueTypes.contains("debugging") {
            return "Debugging and troubleshooting"
        } else if uniqueTypes.contains("documentation") {
            return "Documentation work"
        } else {
            return "Recent activity"
        }
    }
    
    private func determineProjectStatus(from activities: [Activity], lastActivity: Date) -> Project.ProjectStatus {
        let hoursSinceLastActivity = Date().timeIntervalSince(lastActivity) / 3600
        
        if hoursSinceLastActivity < 2 {
            return .active
        } else if hoursSinceLastActivity < 24 {
            return .paused
        } else {
            return .completed
        }
    }
    
    private func parseActivityDate(_ dateString: String) -> Date? {
        // Use the existing date parsing logic from the Activity model
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }    
    // MARK: - Git Activity Fetching
    private func fetchGitActivities() async throws -> [GitActivity] {
        // This would typically connect to your Git activity API endpoint
        // For now, we'll create mock data and later connect to actual API
        
        let mockActivities = [
            GitActivity(
                id: UUID().uuidString,
                repository: "flowstate-ai/ios-app",
                branch: "develop",
                commitMessage: "Add multi-project dashboard view",
                author: "Neo Todak",
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                type: .commit,
                additions: 145,
                deletions: 23,
                files_changed: 4
            ),
            GitActivity(
                id: UUID().uuidString,
                repository: "flowstate-ai/backend",
                branch: "main",
                commitMessage: "Fix activity aggregation API",
                author: "Neo Todak", 
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                type: .push,
                additions: 67,
                deletions: 12,
                files_changed: 2
            ),
            GitActivity(
                id: UUID().uuidString,
                repository: "todak-ai/claude-desktop",
                branch: "feature/memory-improvements",
                commitMessage: "Enhance memory saving with CTK compliance",
                author: "Neo Todak",
                timestamp: Date().addingTimeInterval(-14400), // 4 hours ago
                type: .pull_request,
                additions: 234,
                deletions: 45,
                files_changed: 7
            )
        ]
        
        return mockActivities
    }
    
    // MARK: - Enhanced Refresh Method
    func refreshEnhanced() async {
        guard !serviceKey.isEmpty else {
            error = "Please configure your service key in Settings"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Store previous state for comparison
            let previousProject = currentProject
            let previousActivityCount = activities.count
            
            // Fetch regular activities
            let newActivities = try await fetchActivities()
            
            // Fetch Git activities
            let newGitActivities = try await fetchGitActivities()
            
            // Update state
            self.activities = newActivities
            self.gitActivities = newGitActivities
            
            // Update current projects (multiple)
            updateCurrentProjects(from: newActivities)
            
            // Keep backward compatibility - set currentProject to most recent
            let newCurrentProject = currentProjects.first?.name
            self.currentProject = newCurrentProject
            
            // Get unique machines from recent activities
            self.activeMachines = Array(Set(newActivities.compactMap { $0.machine }))
                .sorted()
                .prefix(5)
                .map { String($0) }
            
            // Calculate stats
            calculateStats(from: newActivities)
            
            // 🔔 NOTIFICATION LOGIC (keeping existing logic)
            if notificationsEnabled && !isLoading {
                // Detect project changes
                if previousProject != newCurrentProject {
                    notificationManager.sendProjectChangeNotification(
                        from: previousProject, 
                        to: newCurrentProject
                    )
                }
                
                // Detect new activities
                if newActivities.count > previousActivityCount {
                    let newActivityCount = newActivities.count - previousActivityCount
                    
                    // Send notification for new activities
                    if let latestActivity = newActivities.first {
                        notificationManager.sendNewActivityNotification(activity: latestActivity)
                    }
                    
                    print("🔔 Detected \(newActivityCount) new activities")
                }
                
                // Send data refresh notification (every few refreshes to avoid spam)
                if newActivities.count > 0 && lastActivityCount != newActivities.count {
                    notificationManager.sendDataRefreshNotification(activityCount: newActivities.count)
                    lastActivityCount = newActivities.count
                }
            }
            
        } catch {
            print("FlowState Error: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }