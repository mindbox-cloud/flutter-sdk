# Mindbox SDK example

## Initialization

```dart
import 'package:flutter/material.dart';
import 'package:mindbox/mindbox.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Mindbox.instance.init(
    configuration: Configuration(
      domain: 'api.mindbox.ru',
      endpointIos: 'your-ios-endpoint',
      endpointAndroid: 'your-android-endpoint',
      subscribeCustomerIfCreated: true,
    ),
  );
  Mindbox.instance.setLogLevel(logLevel: LogLevel.debug);

  runApp(const MyApp());
}
```

## Device UUID and push tokens

```dart
Mindbox.instance.getDeviceUUID((uuid) => print('Device UUID: $uuid'));
Mindbox.instance.getTokens((tokens) => print('Push tokens: $tokens'));
```

## Operations

```dart
Mindbox.instance.executeAsyncOperation(
  operationSystemName: 'ViewProduct',
  operationBody: {
    'viewProduct': {
      'product': {
        'ids': {'website': '1'},
      },
    },
  },
);

Mindbox.instance.executeSyncOperation(
  operationSystemName: 'GetRecommendations',
  operationBody: {},
  onSuccess: (response) => print(response),
  onError: (error) => print(error.message),
);
```

## Push notifications

```dart
Mindbox.instance.onPushClickReceived((link, payload) {
  print('Push clicked: $link, $payload');
});

Mindbox.instance.refreshNotificationPermissionStatus();
```

## In-app messages

```dart
Mindbox.instance.registerInAppCallback(callbacks: [
  CustomInAppCallback(
    (id, redirectUrl, payload) => print('In-app clicked: $id'),
    (id) => print('In-app dismissed: $id'),
  ),
]);
```

## Full example

A complete app with push notifications (Firebase, Huawei, RuStore, APNs), notification center and in-app callbacks is in [example/flutter_example](https://github.com/mindbox-cloud/flutter-sdk/tree/develop/example/flutter_example).

See the [Flutter SDK documentation](https://developers.mindbox.ru/docs/flutter-sdk) for setup details.
