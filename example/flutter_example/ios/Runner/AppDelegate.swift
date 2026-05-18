import UIKit
import Flutter
import mindbox_ios
import Mindbox
import UserNotifications

// Example AppDelegate migrated to UISceneDelegate. Requires Flutter >= 3.41.
// Mindbox-side notes:
// https://github.com/mindbox-cloud/flutter-sdk/blob/develop/UISCENE_MIGRATION.md
// Legacy (pre-migration) variant is kept commented out at the bottom for reference.
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var eventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        UNUserNotificationCenter.current().delegate = self

        // tracking sources of referrals to the application via push notifications
        Mindbox.shared.track(.launch(launchOptions))

        // registering background tasks for iOS above 13
        if #available(iOS 13.0, *) {
            Mindbox.shared.registerBGTasks()
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }

        // Plugin / FlutterEventChannel setup lives in didInitializeImplicitFlutterEngine(_:).
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let eventChannel = FlutterEventChannel(
            name: "cloud.mindbox.flutter_example.notifications",
            binaryMessenger: engineBridge.applicationRegistrar.messenger()
        )
        eventChannel.setStreamHandler(self)
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
        // Universal link in cold-start (AppDelegate-only flow).
        // Under UISceneDelegate this method is not invoked — see SceneDelegate.swift.
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
        completionHandler([.alert, .badge, .sound])
        notifyFlutterNewData()
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Send click to Mindbox
        Mindbox.shared.pushClicked(response: response)

        // Sending the fact that the application was opened when switching to push notification
        Mindbox.shared.track(.push(response))
        completionHandler()
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
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

// MARK: - Legacy variant (pre-UISceneDelegate, Flutter < 3.41)
//
// Kept here as a reference for projects that haven't migrated to
// UISceneDelegate yet (Info.plist without `UIApplicationSceneManifest`).
// To roll back: replace the class above with the version below, remove
// `SceneDelegate.swift` and the `UIApplicationSceneManifest` entry in
// `Info.plist`.
//
// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//     private var eventSink: FlutterEventSink?
//
//     override func application(
//         _ application: UIApplication,
//         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {
//         UIApplication.shared.registerForRemoteNotifications()
//         registerForRemoteNotifications()
//
//         // Tracks the source that opened the app (push, universal link, etc.).
//         Mindbox.shared.track(.launch(launchOptions))
//
//         if #available(iOS 13.0, *) {
//             Mindbox.shared.registerBGTasks()
//         } else {
//             UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
//         }
//
//         // Under AppDelegate-only flow, `window`/`rootViewController` are
//         // ready by this point — plugin and channel setup happen here.
//         let controller = window?.rootViewController as! FlutterViewController
//         let eventChannel = FlutterEventChannel(
//             name: "cloud.mindbox.flutter_example.notifications",
//             binaryMessenger: controller.binaryMessenger
//         )
//         eventChannel.setStreamHandler(self)
//         GeneratedPluginRegistrant.register(with: self)
//
//         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }
//
//     override func application(
//         _ application: UIApplication,
//         continue userActivity: NSUserActivity,
//         restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
//     ) -> Bool {
//         // Under AppDelegate-only flow universal links arrive here.
//         // After scene migration this method is not invoked — the event
//         // is handled by `SceneDelegate.scene(_:continue:)` instead.
//         Mindbox.shared.track(.universalLink(userActivity))
//         return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
//     }
//
//     func registerForRemoteNotifications() {
//         UNUserNotificationCenter.current().delegate = self
//         DispatchQueue.main.async {
//             UNUserNotificationCenter.current().requestAuthorization(
//                 options: [.alert, .sound, .badge]
//             ) { granted, error in
//                 if let error = error {
//                     print("NotificationsRequestAuthorization failed: \(error.localizedDescription)")
//                 }
//                 Mindbox.shared.notificationsRequestAuthorization(granted: granted)
//             }
//         }
//     }
//
//     // The remaining overrides (`didRegisterForRemoteNotificationsWithDeviceToken`,
//     // `performFetchWithCompletionHandler`, the two `userNotificationCenter`
//     // delegate methods, the `FlutterStreamHandler` extension) are
//     // identical to the migrated variant above.
// }
