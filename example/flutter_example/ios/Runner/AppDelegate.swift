import UIKit
import Flutter
import mindbox_ios
import Mindbox
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: MindboxFlutterAppDelegate {
    private var eventSink: FlutterEventSink?
    
    override func shouldRegisterForRemoteNotifications() -> Bool {
        return true
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        GeneratedPluginRegistrant.register(with: self)
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let eventChannel = FlutterEventChannel(name: "cloud.mindbox.flutter_example.notifications", binaryMessenger: controller.binaryMessenger)
        
        eventChannel.setStreamHandler(self)
        
        UNUserNotificationCenter.current().delegate = self
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func notifyFlutterNewData() {
        if let eventSink = eventSink {
            eventSink("newNotification")
        }
    }
    
    func saveNotification(notification: UNNotification) {
        guard let pushData = Mindbox.shared.getMindboxPushData(userInfo: notification.request.content.userInfo) else { return }
        
        let mindboxRemoteMessage = MindboxRemoteMessage(
            uniqueKey: pushData.uniqueKey ?? UUID().uuidString,
            title: pushData.aps?.alert?.title ?? "",
            description: pushData.aps?.alert?.body ?? "",
            pushLink: pushData.clickUrl,
            imageUrl: pushData.imageUrl,
            pushActions: pushData.buttons?.map { PushAction(uniqueKey: $0.uniqueKey ?? UUID().uuidString, text: $0.text ?? "", url: $0.url ?? "") } ?? [],
            payload: pushData.payload
        )
        
        let userDefaults = UserDefaults.standard
        var notificationsJson = userDefaults.string(forKey: "flutter.notifications") ?? "[]"
        
        if var notifications = try? JSONDecoder().decode([String].self, from: notificationsJson.data(using: .utf8)!) {
            if let jsonData = try? JSONEncoder().encode(mindboxRemoteMessage),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                notifications.append(jsonString)
            }
            
            if let updatedNotificationsData = try? JSONEncoder().encode(notifications),
               let updatedNotificationsString = String(data: updatedNotificationsData, encoding: .utf8) {
                userDefaults.set(updatedNotificationsString, forKey: "flutter.notifications")
            }
        }
        userDefaults.synchronize()
        notifyFlutterNewData()
    }
    
    // Обработка уведомлений, когда приложение активно
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
        saveNotification(notification: notification)
        
    }
    
    // Обработка уведомлений, когда приложение в фоне или закрыто
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        saveNotification(notification: response.notification)
    }
    
    open override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if let notification = userInfo as? UNNotification {
            saveNotification(notification: notification)
        }
        super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
        completionHandler(.newData)
    }
}

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
