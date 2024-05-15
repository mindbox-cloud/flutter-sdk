import UIKit
import mindbox_ios
import Flutter

@UIApplicationMain
@objc class AppDelegate: MindboxFlutterAppDelegate {
    
    override func shouldRegisterForRemoteNotifications() -> Bool {
        return false
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        GeneratedPluginRegistrant.register(with: self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

