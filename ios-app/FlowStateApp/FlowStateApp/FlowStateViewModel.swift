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
    
    private let supabaseURL = "https://uzamamymfzhelvkwpvgt.supabase.co"
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
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
        guard !serviceKey.isEmpty else {
            error = "Please configure your service key in Settings"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Fetch recent activities
            let activities = try await fetchActivities()
            
            self.activities = activities
            
            // Update current project (most recent activity)
            self.currentProject = activities.first?.project_name
            
            // Get unique machines from recent activities
            self.activeMachines = Array(Set(activities.compactMap { $0.machine }))
                .sorted()
                .prefix(5)
                .map { String($0) }
            
            // Calculate stats
            calculateStats(from: activities)
            
        } catch {
            print("FlowState Error: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
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
}