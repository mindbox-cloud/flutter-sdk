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

`MindboxEmbeddedBlock` shows the block configured for a place in the admin panel. Give it the
place's system name and a height; the layout sets its position and width.

```dart
MindboxEmbeddedBlock(
  placeSystemName: 'stories',
  height: 104,
  placeholder: (_) => const StoriesSkeleton(),
  errorBuilder: (_) => const StoriesUnavailable(),
  onFail: (reason) => log('stories failed: $reason'),
)
```

- `onLoad`, `onEmpty` and `onFail` report how the load ended. Keep the block in the layout after
  `onEmpty`: a collapsed block still shows content the place gets later.
- `timeout` is counted only while the block's screen is shown, 30 seconds by default.
- `loadingStrategy` sets what the block shows while it loads. The default, `automatic`, keeps the
  block at zero height at a place that has not shown content on this device yet, and at a place
  that has, takes the height a frame after the block is built. `placeholder` takes it from the
  first frame.
- `timeout`, `loadingStrategy` and `animatesReveal` are read only when the block is created; give
  the widget a new `Key` to change them. `height` can change at any time.
- In a lazy list the block is kept alive off screen and comes back without a reload. A kept block
  holds its page in memory; pass `keepAlive: false` on a screen with many blocks.
- The block works on iOS and Android. On other platforms it collapses and reports `onFail` with
  `internalError`.

## Troubleshooting

Refer to the [Example of integration(IOS)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_ios/example) or [Example of integration(Android)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_android/example) in case of any issues.

## Further Help

Reach out to us for further help and we'll be glad to assist.

## License

The library is available as open source under the terms of the [License](https://github.com/mindbox-cloud/android-sdk/blob/develop/LICENSE.md).

For a better understanding of this content, please familiarize yourself with the Mindbox [Flutter SDK](https://developers.mindbox.ru/docs/flutter-sdk-integration) documentation.