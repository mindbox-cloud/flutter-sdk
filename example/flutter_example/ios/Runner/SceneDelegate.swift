import UIKit
import Flutter
import Mindbox

// Sample SceneDelegate forwarding scene events to Mindbox. Requires Flutter >= 3.35.
// Mindbox-side notes:
// https://github.com/mindbox-cloud/flutter-sdk/blob/develop/mindbox_ios/UISCENE_MIGRATION.md
@available(iOS 13.0, *)
class SceneDelegate: FlutterSceneDelegate {

    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        Mindbox.shared.track(.launchScene(connectionOptions))
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    override func scene(
        _ scene: UIScene,
        continue userActivity: NSUserActivity
    ) {
        Mindbox.shared.track(.universalLink(userActivity))
        super.scene(scene, continue: userActivity)
    }
}
