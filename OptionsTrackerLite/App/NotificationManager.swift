import Foundation
import UserNotifications
import SwiftData

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("❌ Notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Schedule a notification for a trade expiring soon
    func scheduleExpirationNotification(for trade: Trade, daysBeforeExpiry: Int = 3) async {
        guard trade.sendNotifications else { return }
        
        let calendar = Calendar.current
        guard let notificationDate = calendar.date(
            byAdding: .day,
            value: -daysBeforeExpiry,
            to: trade.expirationDate
        ) else { return }
        
        // Only schedule if date is in the future and trade is open
        guard notificationDate > Date(), !trade.isClosed else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Option Expiring Soon"
        content.body = "\(trade.ticker) \(trade.type.rawValue) expires in \(daysBeforeExpiry) days"
        content.sound = .default
        content.categoryIdentifier = "TRADE_EXPIRY"
        content.userInfo = ["tradeId": trade.id.uuidString]
        
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "trade-\(trade.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled notification for \(trade.ticker) on \(notificationDate)")
        } catch {
            print("❌ Failed to schedule notification: \(error.localizedDescription)")
        }
    }
    
    /// Cancel notification for a specific trade
    func cancelNotification(for trade: Trade) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["trade-\(trade.id.uuidString)"])
        print("🗑️ Cancelled notification for \(trade.ticker)")
    }
    
    /// Reschedule all notifications (useful after settings change)
    func rescheduleAllNotifications(for profiles: [ClientProfile], daysBeforeExpiry: Int = 3) async {
        // Cancel all existing
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Reschedule open trades
        for profile in profiles {
            for trade in profile.trades where !trade.isClosed && trade.sendNotifications {
                await scheduleExpirationNotification(for: trade, daysBeforeExpiry: daysBeforeExpiry)
            }
        }
        
        print("♻️ Rescheduled all notifications")
    }
}
