import UIKit
import Flutter
import mindbox_ios
import Mindbox
import UserNotifications

// Example variant using `MindboxFlutterAppDelegate` as base class (APNS,
// `.push`, BG tasks come from the base class). Migrated to UISceneDelegate.
// Requires Flutter >= 3.41.
// Mindbox-side notes:
// https://github.com/mindbox-cloud/flutter-sdk/blob/develop/UISCENE_MIGRATION.md
// Legacy (pre-migration) variant is kept commented out at the bottom for reference.
@main
@objc class AppDelegateUsedMindboxDelegate: MindboxFlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var eventSink: FlutterEventSink?

    override func shouldRegisterForRemoteNotifications() -> Bool {
        return true
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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

extension AppDelegateUsedMindboxDelegate: FlutterStreamHandler {
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
// @main
// @objc class AppDelegateUsedMindboxDelegate: MindboxFlutterAppDelegate {
//     private var eventSink: FlutterEventSink?
//
//     override func shouldRegisterForRemoteNotifications() -> Bool {
//         return true
//     }
//
//     override func application(
//         _ application: UIApplication,
//         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {
//         UIApplication.shared.registerForRemoteNotifications()
//         GeneratedPluginRegistrant.register(with: self)
//
//         // Under AppDelegate-only flow `window`/`rootViewController` are
//         // ready here, so plugin and channel setup happen in this method.
//         let controller = window?.rootViewController as! FlutterViewController
//         let eventChannel = FlutterEventChannel(
//             name: "cloud.mindbox.flutter_example.notifications",
//             binaryMessenger: controller.binaryMessenger
//         )
//         eventChannel.setStreamHandler(self)
//
//         UNUserNotificationCenter.current().delegate = self
//
//         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }
//
//     // The remaining `userNotificationCenter(_:willPresent:...)` override
//     // and the `FlutterStreamHandler` extension are identical to the
//     // migrated variant above.
// }
