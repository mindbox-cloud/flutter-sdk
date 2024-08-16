import UIKit
import Flutter
import mindbox_ios
import Mindbox
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var eventSink: FlutterEventSink?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        UIApplication.shared.registerForRemoteNotifications()
        
        // Calling the notification request method
        registerForRemoteNotifications()
        
        // tracking sources of referrals to the application via push notifications
        Mindbox.shared.track(.launch(launchOptions))
      
        // registering background tasks for iOS above 13
        if #available(iOS 13.0, *) {
            Mindbox.shared.registerBGTasks()
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
        
        //Used for notification center
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let eventChannel = FlutterEventChannel(name: "cloud.mindbox.flutter_example.notifications", binaryMessenger: controller.binaryMessenger)
        eventChannel.setStreamHandler(self)
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            // Transfer to SDK APNs token
            Mindbox.shared.apnsTokenUpdate(deviceToken: deviceToken)
        }
    
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
      ) -> Bool {
        // Passing the link if the application is opened via universalLink
        Mindbox.shared.track(.universalLink(userActivity))
        return super.application(application, continue: userActivity, restorationHandler:
        restorationHandler)
      }
    
    // Register background tasks for iOS up to 13
    override func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            Mindbox.shared.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Implement display of standard notifications
        completionHandler([.list, .badge, .sound, .banner])
        notifyFlutterNewData()
    }
    
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
            // Send click to Mindbox
            Mindbox.shared.pushClicked(response: response)
            
            // Sending the fact that the application was opened when switching to push notification
            Mindbox.shared.track(.push(response))
            completionHandler()
            super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        }
    
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().requestAuthorization(options: [ .alert, .sound, .badge]) { granted, error in
                print("Permission granted: \(granted)")
                if let error = error {
                    print("NotificationsRequestAuthorization failed with error: \(error.localizedDescription)")
                }
                Mindbox.shared.notificationsRequestAuthorization(granted: granted)
            }
        }
    }
    
    func notifyFlutterNewData() {
        if let eventSink = eventSink {
            eventSink("newNotification")
        }
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
