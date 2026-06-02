# Mindbox Flutter SDK with Swift Package Manager

The plugin ships SPM alongside CocoaPods. **Flutter 3.44+ enables SPM by
default** ([flutter#184495][spm-pr]); older releases need
`flutter config --enable-swift-package-manager` (SPM needs Flutter ≥ 3.29; the
per-project `config:` block in `pubspec.yaml` needs ≥ 3.35). The `Runner` gets
`Mindbox` automatically through the plugin — only two Mindbox-specific steps are
manual.

> ⚠️ **Don't load Mindbox through both managers.** On 3.44+ SPM is on by default,
> so leaving `pod 'Mindbox'` in your `Podfile` links Mindbox twice → launch
> crash `Fatal error: ... Expected CDEvent but found CDEvent`. To stay on
> CocoaPods, opt out: `enable-swift-package-manager: false` (pubspec) or
> `flutter config --no-enable-swift-package-manager`.

## 1. Notification extensions

`Runner` project → **Package Dependencies** → **+** →
`https://github.com/mindbox-cloud/ios-sdk`, rule **Up to Next Major** from your
SDK version (e.g. `2.15.1` — a range, not "Exact"). Add the products:

| Product | Add to target |
|---|---|
| `MindboxNotificationsService` | Notification **Service** Extension |
| `MindboxNotificationsContent` | Notification **Content** Extension |
| `Mindbox` | **None** — `Runner` already gets it via the plugin |

## 2. Remove the Mindbox pods

Delete `pod 'Mindbox'` (`Runner`) and `pod 'MindboxNotifications'` (each
extension) from the `Podfile`, then `flutter run`. If every plugin you use
supports SPM, drop CocoaPods entirely — delete the `Podfile` and
`pod deintegrate` (see [`example/flutter_example`][example]).

## Notes

- ObjC `MindboxFlutterAppDelegateObjc` is CocoaPods-only and deprecated; SPM
  apps use the Swift `MindboxFlutterAppDelegate`.
- Project-level `ios-sdk` and the plugin's copy are the same package (same URL)
  → one resolved version. Keep your range inclusive of the plugin's pin; don't
  pin a different "Exact".

[spm-pr]: https://github.com/flutter/flutter/pull/184495
[example]: https://github.com/mindbox-cloud/flutter-sdk/tree/develop/example/flutter_example
