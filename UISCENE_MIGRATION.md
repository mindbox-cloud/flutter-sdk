# Migrating a Mindbox Flutter SDK integration to UISceneDelegate

Starting with Flutter 3.35 the iOS engine ships `FlutterSceneDelegate`, and
since Flutter 3.41 `UISceneDelegate`-based lifecycle is the recommended path
for new iOS Flutter apps. The official Flutter migration guide is the
authoritative source for everything not Mindbox-specific:

- [Flutter UISceneDelegate migration guide][flutter-uiscene]

This document only describes the Mindbox-side glue you need on top of the
Flutter migration: where to forward `.launchScene` and `.universalLink`
events, and what stays in your `AppDelegate`. It does **not** repeat the
Flutter-side steps already covered in the link above (`Info.plist` scene
manifest, `FlutterImplicitEngineDelegate` boilerplate, etc.) — follow them
there and use this page for the Mindbox-specific bits.

If your `Info.plist` does **not** contain `UIApplicationSceneManifest`,
nothing changes for you. The Mindbox iOS SDK pod itself does not depend on
any scene-specific Flutter API, so it keeps building and running on every
Flutter version we supported before. You can update to the latest Mindbox
SDK without touching your code.

## Why this matters for Mindbox integrators

Under `UIApplicationSceneManifest` two `AppDelegate` callbacks Mindbox
previously relied on stop working as before:

- `application(_:didFinishLaunchingWithOptions:)` still fires, but
  `launchOptions` is `nil`, so `Mindbox.shared.track(.launch(launchOptions))`
  tracks nothing useful.
- `application(_:continue:restorationHandler:)` is never invoked — universal
  links arrive in `scene(_:continue:)` instead.

To keep Mindbox receiving launch and universal-link events you need to
forward them from your scene delegate.

## Prerequisites

- **Flutter ≥ 3.41** — required for `FlutterImplicitEngineDelegate` on the
  app side (see the Flutter guide above).
- iOS deployment target ≥ 13.0.

## What to add in your scene delegate

Copy
[`example/flutter_example/ios/Runner/SceneDelegate.swift`](https://github.com/mindbox-cloud/flutter-sdk/blob/develop/example/flutter_example/ios/Runner/SceneDelegate.swift)
into your `Runner` target. The two relevant calls:

```swift
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
```

That replaces, respectively, `Mindbox.shared.track(.launch(launchOptions))`
in `application(_:didFinishLaunchingWithOptions:)` and
`Mindbox.shared.track(.universalLink(userActivity))` in
`application(_:continue:restorationHandler:)`.

You may keep both AppDelegate-side and SceneDelegate-side calls — in scene
mode the AppDelegate-side `.launch(nil)` and `application(_:continue:)` are
inert (`launchOptions == nil`, the method is not invoked), so the two paths
do not produce duplicate events.

## What stays unchanged in your AppDelegate

Even after the scene migration you keep all of the following on your
`AppDelegate` (typically a subclass of `MindboxFlutterAppDelegate`):

- `Mindbox.shared.apnsTokenUpdate(deviceToken:)` in
  `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
- `Mindbox.shared.pushClicked(response:)` and
  `Mindbox.shared.track(.push(response))` in your
  `UNUserNotificationCenterDelegate` methods.
- `Mindbox.shared.registerBGTasks()`.
- Notification permission requests.

`UNUserNotificationCenterDelegate` is a process-global API and is not
affected by scene mode, so push handling needs no changes.

`MindboxFlutterAppDelegate` itself is scene-safe — it does not touch
`window` or `rootViewController` — and continues to work as a base class
unchanged.

## Notification Service / Content Extensions

`MindboxNotificationServiceExtension` and
`MindboxNotificationContentExtension` are extension processes and have
nothing to do with the host app's scene flow. They need no changes.

## Reference implementation

[`example/flutter_example/ios/Runner`](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/example/flutter_example/ios/Runner)
is fully migrated and serves as a working reference for both the
Flutter-side and Mindbox-side parts of the migration.

[flutter-uiscene]: https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
