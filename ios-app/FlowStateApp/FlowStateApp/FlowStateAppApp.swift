//
//  FlowStateAppApp.swift
//  FlowStateApp
//
//  Created by broneotodak on 05/07/2025.
//

import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
struct FlowStateAppApp: App {
    @StateObject private var viewModel = FlowStateViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onReceive(notificationForAppWillEnterForeground) { _ in
                    // Clear badge when app comes to foreground
                    viewModel.notificationManager.clearBadge()
                    
                    // Refresh data when app becomes active
                    Task {
                        await viewModel.refresh()
                    }
                }
        }
    }
    
    private var notificationForAppWillEnterForeground: NotificationCenter.Publisher {
        #if os(iOS)
        return NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        #elseif os(macOS)
        return NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)
        #else
        return NotificationCenter.default.publisher(for: Notification.Name("AppWillEnterForeground"))
        #endif
    }
}
