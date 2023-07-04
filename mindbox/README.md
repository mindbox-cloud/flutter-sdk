[![Pub Version](https://img.shields.io/pub/v/mindbox?color=blue)](https://pub.dev/packages/mindbox)

This plugin is a wrapper over the native Mindbox([iOS](https://github.com/mindbox-moscow/ios-sdk),
[Android](https://github.com/mindbox-moscow/android-sdk)) libraries that allows to
receive and handle push notifications.

## Features

* Receive and show push notification in both mobile platforms.
* Receive push notification data(link, payload) in Flutter.
* Execute sync/async operations.
* Display In-App

## Getting started

This plugin depends on the configuration of push notifications on native platforms. It's necessary
to follow the steps specified in the guide:

* [Mindbox Flutter SDK](https://developers.mindbox.ru/docs/flutter-sdk-integration)

## Usage

### Initialization

```dart
import 'package:mindbox/mindbox.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();

   final config = Configuration(
     domain: "your domain",
     endpointIos: "iOs endpoint",
     endpointAndroid: "Android endpoint",
     subscribeCustomerIfCreated: true,
   );
 
   Mindbox.instance.init(configuration: config);

   runApp(MyApp());
}
```

### Handling push click

```dart
Mindbox.instance.onPushClickReceived((link, payload) {
  print(payload);
  switch (link) {
    case 'mindbox.cloud':
      Navigator.push(context, MaterialPageRoute(builder: (context) => ContentPage()));
      break;
    case 'mindbox.cloud/user':
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
      break;
    default:
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
  }
});
```

### Getting device UUID

```dart
Mindbox.instance.getDeviceUUID((uuid) => print(uuid));
```

### Getting APNS/FMS/HMS token

```dart
Mindbox.instance.getToken((token) => print(token));
```

### Execute async operation

```dart
Mindbox.instance.executeAsyncOperation(
  operationSystemName: 'operationName',
  operationBody: {'example': 'body'},
);
```

### Execute sync operation

```dart
Mindbox.instance.executeSyncOperation(
  operationSystemName: 'operationName',
  operationBody: {'example': 'body'},
  onSuccess: (String response) {
    jsonDecode(response);
  },
  onError: (MindboxError error){
    if (error is MindboxProtocolError) {
      print(error.code);
    }
    print(error.message);
    jsonDecode(error.data);
  },
);
```

### In-App click handling

```dart
 Mindbox.instance.onInAppClickRecieved((id, redirectUrl, payload) {
  print(id);
  print(redirectUrl);
  print(payload);
});
```

### In-App dismiss handling

```dart
 Mindbox.instance.onInAppDismissed((id){
  print(id);
});
```