import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let wasAuthorized = isAuthorized
        isAuthorized = settings.authorizationStatus == .authorized
        
        print("📱 Notification status check:")
        print("   Authorization: \(settings.authorizationStatus.rawValue) (\(settings.authorizationStatus))")
        print("   Alert Setting: \(settings.alertSetting.rawValue)")
        print("   Badge Setting: \(settings.badgeSetting.rawValue)")  
        print("   Sound Setting: \(settings.soundSetting.rawValue)")
        print("   Is Authorized: \(isAuthorized)")
        
        if wasAuthorized != isAuthorized {
            print("📱 Authorization status changed: \(wasAuthorized) → \(isAuthorized)")
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
        print("📤 Attempting to send notification:")
        print("   Title: \(title)")
        print("   Body: \(body)")
        print("   Current authorization: \(isAuthorized)")
        
        guard isAuthorized else { 
            print("❌ Notification blocked: Not authorized")
            return 
        }
        
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
        
        print("📤 Adding notification request...")
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Notification error: \(error.localizedDescription)")
                    print("   Error details: \(error)")
                } else {
                    print("✅ Notification sent successfully: \(title)")
                    print("   Request ID: \(request.identifier)")
                }
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
    
    func sendTestNotification() {
        Task {
            // Force check authorization status first
            await checkAuthorizationStatus()
            
            await MainActor.run {
                guard isAuthorized else { 
                    print("❌ Test notification failed: Not authorized. Status: \(isAuthorized)")
                    return 
                }
                
                let title = "🧪 Test Notification"
                let body = "FlowState notifications are working correctly!"
                
                print("🧪 Sending test notification with authorization: \(isAuthorized)")
                sendMemoryUpdateNotification(title: title, body: body)
            }
        }
    }
}
