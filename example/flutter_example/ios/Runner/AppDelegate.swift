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
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
        notifyFlutterNewData()
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
