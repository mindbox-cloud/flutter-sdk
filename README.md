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
mindbox: ^2.8.2
```

### Initialization

Initialize the Mindbox SDK in your Activity or Application class. Check documentation [here](https://developers.mindbox.ru/docs/sdk-initialization-flutter) for more details.

### Operations

Learn how to send events to Mindbox. Create a new Operation class object and set the respective parameters. Check the [documentation](https://developers.mindbox.ru/docs/integration-actions-flutter) for more details.

### Push Notifications

Mindbox SDK helps handle push notifications. Configuration and usage instructions can be found in the SDK documentation [here](https://developers.mindbox.ru/docs/firebase-send-push-notifications-flutter),  [here](https://developers.mindbox.ru/docs/huawei-send-push-notifications-flutter) and [here](https://developers.mindbox.ru/docs/ios-send-push-notifications-flutter).

## Troubleshooting

Refer to the [Example of integration(IOS)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_ios/example) or [Example of integration(Android)](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/mindbox_android/example) in case of any issues.

## Further Help

Reach out to us for further help and we'll be glad to assist.

## License

The library is available as open source under the terms of the [License](https://github.com/mindbox-cloud/android-sdk/blob/develop/LICENSE.md).

For a better understanding of this content, please familiarize yourself with the Mindbox [Flutter SDK](https://developers.mindbox.ru/docs/flutter-sdk-integration) documentation.