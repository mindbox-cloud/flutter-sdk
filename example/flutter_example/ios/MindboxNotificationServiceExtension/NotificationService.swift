//
//  NotificationService.swift
//  MindboxNotificationServiceExtension
//
//  Created by Dmitry Erofeev on 24.04.2024.
//

import UserNotifications
import MindboxNotifications
import Mindbox

class NotificationService: UNNotificationServiceExtension {
    
    static let suiteName = "group.cloud.Mindbox.cloud.mindbox.flutterExample"
    lazy var mindboxService = MindboxNotificationService()
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        saveNotification(request: request)
        mindboxService.didReceive(request, withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        mindboxService.serviceExtensionTimeWillExpire()
    }
    
    // We use UserDefaults to save push data for example purposes only. Don't use this solution for yourself
    func saveNotification(request: UNNotificationRequest) {
        guard let pushData = Mindbox.shared.getMindboxPushData(userInfo: request.content.userInfo) else {
            print("Failed to get Mindbox push data")
            return
        }
        
        let mindboxRemoteMessage = MindboxRemoteMessage(
            uniqueKey: pushData.uniqueKey ?? UUID().uuidString,
            title: pushData.aps?.alert?.title ?? "",
            description: pushData.aps?.alert?.body ?? "",
            pushLink: pushData.clickUrl,
            imageUrl: pushData.imageUrl,
            pushActions: pushData.buttons?.map { PushAction(uniqueKey: $0.uniqueKey ?? UUID().uuidString, text: $0.text ?? "", url: $0.url ?? "") } ?? [],
            payload: pushData.payload
        )
        
        
        let userDefaults = UserDefaults(suiteName: NotificationService.suiteName)
        let notificationsJson = userDefaults?.string(forKey: "notifications") ?? "[]"
        
        do {
            var notifications = try JSONDecoder().decode([String].self, from: Data(notificationsJson.utf8))
            
            let jsonData = try JSONEncoder().encode(mindboxRemoteMessage)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                notifications.append(jsonString)
            } else {
                print("Failed to encode mindboxRemoteMessage to String")
            }
            
            let updatedNotificationsData = try JSONEncoder().encode(notifications)
            if let updatedNotificationsString = String(data: updatedNotificationsData, encoding: .utf8) {
                userDefaults?.set(updatedNotificationsString, forKey: "notifications")
            } else {
                print("Failed to encode updated notifications to String")
            }
        } catch {
            print("Error processing notifications: \(error)")
        }
        userDefaults?.synchronize()
    }
}
