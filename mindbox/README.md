[![Pub Version](https://img.shields.io/pub/v/mindbox?color=blue)](https://pub.dev/packages/mindbox)

This plugin is a wrapper over the native Mindbox([iOS](https://github.com/mindbox-moscow/ios-sdk),
[Android](https://github.com/mindbox-moscow/android-sdk)) libraries that allows to
receive and handle push notifications.

## Features

* Receive and show push notification in both mobile platforms.
* Receive push notification data(links) in Flutter.
* Execute sync/async operations

## Getting started

This plugin depends on the configuration of push notifications on native platforms. It's necessary
to follow the steps specified in the guide:

* [Mindbox Flutter SDK](https://developers.mindbox.ru/docs/flutter-sdk)

## Usage

### Initialization

```dart
// Import `mindbox.dart`
import 'package:mindbox/mindbox.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();
   // Initialization configuration
   final config = Configuration(
           domain: "your domain",
           endpointIos: "iOs endpoint",
           endpointAndroid: "Android endpoint",
           subscribeCustomerIfCreated: true);
   // Initialization
   Mindbox.instance.init(configuration: config);

   runApp(MyApp());
}
```

### Handling push click

```dart
Mindbox.instance.onPushClickReceived((link) {
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
Mindbox.instance.getDeviceUUID((uuid) {
  setState(() {
    _deviceUUID = uuid;
  });
});
```

### Getting APNS/FMS token

```dart
Mindbox.instance.getDeviceUUID((uuid) {
  setState(() {
    _deviceUUID = uuid;
  });
});
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