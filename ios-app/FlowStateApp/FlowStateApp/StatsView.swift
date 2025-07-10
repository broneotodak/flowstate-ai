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
            // Parse date using the same logic as in ViewModel
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            
            var date = dateFormatter.date(from: activity.created_at)
            
            if date == nil {
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                date = dateFormatter.date(from: activity.created_at)
            }
            
            if date == nil {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                date = formatter.date(from: activity.created_at)
                
                if date == nil {
                    formatter.formatOptions = [.withInternetDateTime]
                    date = formatter.date(from: activity.created_at)
                }
            }
            
            guard let validDate = date else { return false }
            
            switch range {
            case .today:
                return calendar.isDateInToday(validDate)
            case .week:
                return calendar.isDate(validDate, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(validDate, equalTo: now, toGranularity: .month)
            }
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
