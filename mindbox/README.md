[![PubDev](https://img.shields.io/pub/v/mindbox)](https://pub.dev/packages/mindbox)

# Mindbox SDK for Flutter

The Mindbox SDK allows you to integrate mobile push-notifications, in-app messages and client events into your Flutter projects.

## Getting Started

These instructions will help you integrate the Mindbox SDK into your Flutter app.

### Installation

To integrate Mindbox SDK into your Flutter app, follow the installation process detailed [here](https://developers.mindbox.ru/docs/add-sdk-flutter). Here is an overview:

Add Mindbox's dependency to your pubspec.yaml file:
```markdown
   dependencies:
flutter:
sdk: flutter
mindbox: ^2.8.4
```

### Initialization

Initialize the Mindbox SDK in your Activity or Application class. Check documentation [here](https://developers.mindbox.ru/docs/sdk-initialization-flutter) for more details.

### Operations

Learn how to send events to Mindbox. Create a new Operation class object and set the respective parameters. Check the [documentation](https://developers.mindbox.ru/docs/integration-actions-flutter) for more details.

### Push Notifications

Mindbox SDK helps handle push notifications. Configuration and usage instructions can be found in the SDK documentation [here](https://developers.mindbox.ru/docs/firebase-send-push-notifications-flutter),  [here](https://developers.mindbox.ru/docs/huawei-send-push-notifications-flutter) and [here](https://developers.mindbox.ru/docs/ios-send-push-notifications-flutter).

### Embedded Blocks

Mark a place in your layout with `MindboxEmbeddedBlock` and the SDK decides what goes into it from
the admin panel — the app never learns what the content is, and it can change without a release.
The host owns the size: pass the `height` the block should occupy. A place that ends up without
content collapses to zero height and hands the space back.

```dart
MindboxEmbeddedBlock(
  placeSystemName: 'main-screen-top',
  height: 104,
)
```

The outcome arrives through three callbacks, the same three as in SwiftUI and Compose: `onLoad`
when the content is shown, `onEmpty` when there is nothing to show at the place, and `onFail` with a
`MindboxEmbeddedBlockFailReason` when the block could not be shown. An empty place is a normal
outcome, not a breakage, and comes with no reason. A failure's reason — `networkError` or
`internalError` — is for logs and analytics, not for branching: by the time it arrives the block has
already collapsed or switched to `errorBuilder`. A later SDK may add reasons, so keep a fallback
when matching.

Both looks can be customized, the same way as in SwiftUI and Compose: `placeholder` replaces the
stock loading shimmer, and `errorBuilder` opts into showing a failure instead of collapsing. An
empty place always collapses — a host cannot fill the space of a block that was never meant to be
there.

```dart
MindboxEmbeddedBlock(
  placeSystemName: 'stories',
  height: 104,
  placeholder: (_) => const StoriesSkeleton(),
  errorBuilder: (_) => const StoriesUnavailable(),
  onEmpty: () => setState(() => _showStoriesSection = false),
  onFail: (reason) => log('stories failed: $reason'),
)
```

How long a block may wait for its content before it gives the place back is `timeout`. Left out, it
is the SDK's own budget of 30 seconds. The wait is the user's: it is counted only while the screen
the block stands on is the one being looked at, so a block behind a pushed route keeps the remainder
of its budget for the return.

```dart
MindboxEmbeddedBlock(
  placeSystemName: 'stories',
  height: 104,
  timeout: const Duration(seconds: 5),
)
```

What the block shows until the SDK has decided what goes into it is `loadingStrategy`, the same
three choices as in SwiftUI and Compose. `automatic` — the default — keeps the block hidden until
the place has shown content once on this device and puts a placeholder there from then on, so the
layout does not jump where content is expected and does not flash where it is not. `placeholder`
takes the space up front, worth naming for a place that always has a campaign behind it. `hidden`
never takes it until the content is shown: no placeholder, and no `errorBuilder` on a failure. The
content is revealed with the SDK's own animation — it fades in, and a block that started hidden
grows to its height — unless `animatesReveal` is off; the system's reduced-motion setting turns it
off as well. Turn it off to animate the block's container yourself in `onLoad`.

```dart
MindboxEmbeddedBlock(
  placeSystemName: 'stories',
  height: 104,
  loadingStrategy: MindboxEmbeddedBlockLoadingStrategy.placeholder,
  animatesReveal: false,
)
```

`height` is live: a new value resizes a block already on screen in place — the same content, no
reload. `timeout`, `loadingStrategy` and `animatesReveal` are fixed when the block is created — a
new value is ignored and reported to the log; give the widget a new `Key` to build a block anew.

In a lazy list — a `ListView`, a `GridView` — the block asks to be kept alive off screen by default,
the way the native blocks behave in a scroll: a block scrolled far away keeps its page, and on the
way back it shows the same content at once, with no reload and no shimmer. The price is memory —
every kept block holds its web page for as long as the list lives, and the whole row it stands in is
kept with it. A screen with many blocks can opt out with `keepAlive: false`, and then the block is
disposed with its row like any other widget.

```dart
ListView.builder(
  itemBuilder: (_, index) => index == 0
      ? const MindboxEmbeddedBlock(placeSystemName: 'stories', height: 104)
      : ProductRow(index),
)
```

Available on iOS and Android. On any other platform the block collapses right away and reports
`onFail` with `internalError`, so a layout that hides its section on failure behaves the same
everywhere.

## Troubleshooting

Refer to the [Example of integration(IOS)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_ios/example) or [Example of integration(Android)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_android/example) in case of any issues.

## Further Help

Reach out to us for further help and we'll be glad to assist.

## License

The library is available as open source under the terms of the [License](https://github.com/mindbox-cloud/android-sdk/blob/develop/LICENSE.md).

For a better understanding of this content, please familiarize yourself with the Mindbox [Flutter SDK](https://developers.mindbox.ru/docs/flutter-sdk-integration) documentation.