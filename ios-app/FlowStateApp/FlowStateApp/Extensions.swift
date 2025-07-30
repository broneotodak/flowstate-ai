import SwiftUI
import Foundation

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extension for Time Ago
extension Date {
    var timeAgoShort: String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        if hours < 24 { return "\(hours)h" }
        if days < 7 { return "\(days)d" }
        return "\(days/7)w"
    }
    
    var timeAgoLong: String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) minute\(minutes == 1 ? "" : "s") ago" }
        if hours < 24 { return "\(hours) hour\(hours == 1 ? "" : "s") ago" }
        if days < 7 { return "\(days) day\(days == 1 ? "" : "s") ago" }
        let weeks = days / 7
        return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
    }
}

// MARK: - Color Extension for Predefined Colors
extension Color {
    static let projectColors: [String] = [
        "007AFF", // Blue
        "34C759", // Green  
        "FF9500", // Orange
        "AF52DE", // Purple
        "FF2D92", // Pink
        "5AC8FA", // Light Blue
        "FFCC02", // Yellow
        "FF6482", // Red
        "30D158", // Mint
        "BF5AF2"  // Lavender
    ]
    
    static func randomProjectColor() -> String {
        return projectColors.randomElement() ?? "007AFF"
    }
}

// MARK: - String Extension for Git Activity Colors
extension String {
    var asColor: Color {
        switch self.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "mint": return .mint
        case "yellow": return .yellow
        default: return .gray
        }
    }
}