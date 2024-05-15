# Example app for Mindbox SDK for flutter

This is an example of SDK [integration](https://developers.mindbox.ru/docs/flutter-sdk-integration)

## Getting Started

### IOS
1. Clone [flutter-sdk repository](https://github.com/mindbox-cloud/flutter-sdk).
2. Go to `flutter-sdk/example/flutter_example`.
3. From the terminal:
 ```
 flutter pub get
 ```
4. Make sure you have CocoaPods installed or install it according to the instructions.
5. Go to `ios/Runner`.
6. Install pods:
```
pod install
```
7. Launch `Runner.xcworkspace` .
8. Launch app.

Now you can test the in-app on the simulator. 
In our admin panel there are already 3 ready-made in-apps that you can look at. 
To run the application on a real device and try push notifications, follow the instructions below.

9. Change [team](https://developers.mindbox.ru/docs/ios-get-keys) and bundle identifiers and App Group name for next targets:
  - Runner
  - MindboxNotificationServiceExtension
  - MindboxNotificationContentExtension
10. [Configure your endpoints](https://developers.mindbox.ru/docs/add-ios-integration).
11. Change domain and endpoints in the `main.dart` to yours.

### Android
1. Clone [flutter-sdk repository](https://github.com/mindbox-cloud/flutter-sdk).
2. Go to `flutter-sdk/example/flutter_example`.
3. From the terminal:
 ```
 flutter pub get
 ```
4. Open `android` folder in Android Studio.
5. Change `namespace` and `applicationId` in `app/build.gradle` to yours.
6. Add `google-services.json` and `agconnect-services.json` to `android/app`.
- [Get google-services.json](https://developers.mindbox.ru/docs/firebase-get-keys)
- [Get agconnect-services.json](https://developers.mindbox.ru/docs/huawei-get-keys)
7. [Configure your endpoints](https://developers.mindbox.ru/docs/add-ios-integration).
8. Change domain and endpoints in the `main.dart` to yours.
8. Launch app.

### SDK functionality testing
1. To check innap when opening:
  - [Read this](https://help.mindbox.ru/docs/in-app-what-is).
  - Open app.
2. To check the inapp anywhere in the application:
  - [Read this](https://help.mindbox.ru/docs/in-app-location).
  - Replace `operationSystemName` in `syncOperation` and `asyncOperation` in `view_model.dart`.
  - Click to the button `Show in-app` opposite the selected operation.
3. To check push notifications:
  - Read [iOS](https://developers.mindbox.ru/docs/ios-send-push-notifications-flutter).
  - Read [android with Firebase](https://developers.mindbox.ru/docs/firebase-send-push-notifications-flutter).
  - Read [android with Huawei](https://developers.mindbox.ru/docs/huawei-send-push-notifications-flutter).
  - Send a notification from your account.
4. To check rich-push notifications:
  - Read [iOS](https://developers.mindbox.ru/docs/ios-send-rich-push-flutter). 
  - Read [android with Firebase](https://developers.mindbox.ru/docs/firebase-send-push-notifications-flutter). 
  - Read [android with Huawei](https://developers.mindbox.ru/docs/huawei-send-push-notifications-flutter).
  - Send a notification from your account.

### Additionally
  - Currently the In-App only comes once per session.
  - There are comments and links in the flutter example code that can help you.
