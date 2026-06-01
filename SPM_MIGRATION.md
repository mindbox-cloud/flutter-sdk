# Using the Mindbox Flutter SDK with Swift Package Manager

The plugin supports SPM alongside CocoaPods. Flutter's SPM is opt-in (off by
default as of 3.44); the [official Flutter guide][flutter-spm-app] covers the
Flutter-side setup. This document covers only the Mindbox-specific glue.

On CocoaPods **nothing changes** — see [CocoaPods](#cocoapods) at the bottom.

## Prerequisites

- **Flutter ≥ 3.29.** Verified: on 3.29 the plugin resolves as an SPM product;
  on 3.24 Flutter silently falls back to CocoaPods (SPM is not engaged, the SDK
  comes in via the pod).
- Enable SPM:
  - **Flutter ≥ 3.35** — globally with
    `flutter config --enable-swift-package-manager`, or per project in
    `pubspec.yaml`:
    ```yaml
    flutter:
      config:
        enable-swift-package-manager: true
    ```
  - **Flutter 3.29–3.34** — use the global flag only. The per-project `config:`
    block is not recognized yet and makes `flutter pub get` fail with
    `Unexpected child "config" found under "flutter"`.

## Main app — nothing to do

The `Runner` target gets `Mindbox` transitively through the plugin; `flutter
run` / `flutter build ios` resolve and link it for you.

If your `Podfile` declares `pod 'Mindbox'` on the `Runner` target, **remove it**
— Mindbox would then load via both CocoaPods and SPM. See
[Remove the Mindbox pods](#remove-the-mindbox-pods).

## Notification extensions — one manual step

An extension is a native target, so its dependencies come from your Xcode
project, not from Flutter. Wire them once in Xcode:

1. **Runner** project → **Package Dependencies** → **+**.
2. URL: `https://github.com/mindbox-cloud/ios-sdk`
3. **Dependency Rule → Up to Next Major Version**, starting at the SDK version
   you use (e.g. `2.15.1`). Use a range, not "Exact" — see [Versions](#versions).
4. **Add Package**, then in **Choose Package Products**:

   | Product | Add to target |
   |---|---|
   | `Mindbox` | **None** (Runner already gets it via the plugin) |
   | `MindboxNotificationsService` | Notification **Service** Extension |
   | `MindboxNotificationsContent` | Notification **Content** Extension |

Then remove the extensions' CocoaPods integration — see
[Remove the Mindbox pods](#remove-the-mindbox-pods) below.

## Remove the Mindbox pods

Once the main app gets `Mindbox` via the plugin and the extensions are wired to
the SPM products, remove **every** Mindbox-family pod from the `Podfile` — the
`Runner` target's `pod 'Mindbox'` and each extension's
`pod 'MindboxNotifications'`:

```ruby
# DELETE — these are provided by SPM now
pod 'Mindbox'               # in the Runner target
pod 'MindboxNotifications'  # in each notification-extension target
```

Loading the same native SDK through both CocoaPods and SPM links it twice; at
runtime you get duplicate Swift classes and a Core Data crash
(`Fatal error: ... Expected CDEvent but found CDEvent`). Keep every non-Mindbox
pod, then re-run `pod install` (or just `flutter run`).

No `flutter clean` or `pod deintegrate` is needed: Flutter re-adds the SPM
integration on the next build and `pod install` drops the now-unused pods.

If **all** your plugins support SPM (not just Mindbox), you can drop CocoaPods
entirely instead of keeping the hybrid setup — delete the `Podfile` and run
`pod deintegrate`. See the reference example below.

## Versions

SPM identifies a package by URL, so the project-level `ios-sdk` and the one the
plugin pulls in are the same package, resolved to a single version. The plugin
pins an exact version; your "Up to Next Major" range only has to include it.
Don't pin the project to a different "Exact" version — SPM fails the build with
a clear conflict error instead of shipping two versions.

## Unchanged

- Your `AppDelegate`, `Mindbox.shared.*` calls, push handling, in-app callbacks.
- `UISceneDelegate` migration ([UISCENE_MIGRATION.md](UISCENE_MIGRATION.md)) is
  orthogonal to SPM.
- The Objective-C `MindboxFlutterAppDelegateObjc` base class is
  **CocoaPods-only** and deprecated; SPM consumers use the Swift
  `MindboxFlutterAppDelegate` or call `Mindbox.shared.*` from their own
  AppDelegate.

## Reference

[`example/flutter_example`](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/example/flutter_example)
is configured for **pure SPM**: both extensions wired as above and no CocoaPods
at all — every plugin it uses ships SPM, so the `Podfile` was removed
(`pod deintegrate`). A real app keeps CocoaPods only if it still depends on
plugins that don't support SPM yet.

## CocoaPods

If SPM is off (the default), nothing changes: the main app gets the pods via
the plugin's podspec, and your extension targets declare
`pod 'MindboxNotifications'` in the `Podfile` as before. No code or project
changes are needed to update the SDK.

[flutter-spm-app]: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers
