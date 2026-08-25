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

Both outcomes can be customized, the same way as in SwiftUI and Compose: `placeholder` replaces the
stock loading shimmer, and `errorBuilder` opts into showing a failure instead of collapsing. An
empty place always collapses — a host cannot fill the space of a block that was never meant to be
there. `onLoad` and `onFail` report how the load ended.

```dart
MindboxEmbeddedBlock(
  placeSystemName: 'stories',
  height: 104,
  placeholder: (_) => const StoriesSkeleton(),
  errorBuilder: (_) => const StoriesUnavailable(),
  onFail: () => setState(() => _showStoriesSection = false),
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

Both `height` and `timeout` are fixed when the block is created — a new value given to a block
already on screen is ignored and reported to the log. Give the widget a new `Key` to build a block
on new terms.

Available on iOS and Android. On any other platform the block collapses right away and reports
`onFail`, so a layout that hides its section on failure behaves the same everywhere.

## Troubleshooting

Refer to the [Example of integration(IOS)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_ios/example) or [Example of integration(Android)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_android/example) in case of any issues.

## Further Help

Reach out to us for further help and we'll be glad to assist.

## License

The library is available as open source under the terms of the [License](https://github.com/mindbox-cloud/android-sdk/blob/develop/LICENSE.md).

For a better understanding of this content, please familiarize yourself with the Mindbox [Flutter SDK](https://developers.mindbox.ru/docs/flutter-sdk-integration) documentation.