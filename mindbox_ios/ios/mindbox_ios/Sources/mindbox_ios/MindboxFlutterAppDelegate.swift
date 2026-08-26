import UIKit
import Flutter
import Mindbox

open class MindboxFlutterAppDelegate: FlutterAppDelegate {

    open func shouldRegisterForRemoteNotifications() -> Bool {
            return true
    }

    open override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

        if shouldRegisterForRemoteNotifications() {
            registerForRemoteNotifications()
        }
        // Background task registration for iOS 13+
        if #available(iOS 13.0, *) {
            Mindbox.shared.registerBGTasks()
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }

        // Pass the application launch event.
        // Under UISceneDelegate, launchOptions == nil — the real cold-start
        // payload arrives in scene(_:willConnectTo:options:) of the customer's
        // SceneDelegate and must be forwarded via
        // Mindbox.shared.track(.launchScene(...)).
        Mindbox.shared.track(.launch(launchOptions))
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    //    MARK: didRegisterForRemoteNotificationsWithDeviceToken
    //    Pass the APNS token to the Mindbox SDK.
    open override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            Mindbox.shared.apnsTokenUpdate(deviceToken: deviceToken)
        }

    // Background task registration for iOS below 13.
    open override func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            Mindbox.shared.application(application, performFetchWithCompletionHandler: completionHandler)
            super.application(application, performFetchWithCompletionHandler: completionHandler)
        }

    //    MARK: registerForRemoteNotifications
    //    Notification permission request. The completion block must forward the permission status to the Mindbox SDK.
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                print("Permission granted: \(granted)")
                if let error = error {
                    print("NotificationsRequestAuthorization failed with error: \(error.localizedDescription)")
                }
                Mindbox.shared.notificationsRequestAuthorization(granted: granted)
            }
        }
    }

    // Under UISceneDelegate this callback is not invoked — universal links
    // arrive in scene(_:continue:) of the customer's SceneDelegate and
    // must be forwarded via Mindbox.shared.track(.universalLink(...)).
    open override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Pass the link if the application was opened via a universal link.
        Mindbox.shared.track(.universalLink(userActivity))
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    open override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .badge, .sound])
        }

    //    MARK: didReceive response
    //    Push notification click handler.
    open override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {

            // Pass the push click event.
            Mindbox.shared.pushClicked(response: response)

            // Pass the application launch event from push notification tap.
            Mindbox.shared.track(.push(response))

            completionHandler()
            super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        }
}
