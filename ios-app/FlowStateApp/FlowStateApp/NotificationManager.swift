import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    init() {
        Task {
            await requestPermission()
        }
    }
    
    func requestPermission() async {
        do {
            let authorized = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            self.isAuthorized = authorized
            print("🔔 Notification permission: \(authorized)")
        } catch {
            print("❌ Notification permission error: \(error)")
            self.isAuthorized = false
        }
    }
    
    func sendMemoryUpdateNotification(title: String, body: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Trigger immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error)")
            } else {
                print("✅ Notification sent: \(title)")
            }
        }
    }
    
    func sendNewActivityNotification(activity: Activity) {
        let title = "🌊 New Flow State Activity"
        let body = activity.project_name != nil ? 
            "\(activity.activity_description) • \(activity.project_name!)" :
            activity.activity_description
        
        sendMemoryUpdateNotification(title: title, body: body)
    }
    
    func sendProjectChangeNotification(from oldProject: String?, to newProject: String?) {
        guard oldProject != newProject else { return }
        
        let title = "🎯 Project Switch Detected"
        let body = newProject != nil ? 
            "Now working on: \(newProject!)" :
            "Project activity ended"
        
        sendMemoryUpdateNotification(title: title, body: body)
    }
    
    func sendDataRefreshNotification(activityCount: Int) {
        let title = "🔄 FlowState Memory Updated"
        let body = "Refreshed with \(activityCount) recent activities"
        
        sendMemoryUpdateNotification(title: title, body: body)
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
