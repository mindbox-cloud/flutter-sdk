import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_example/view/Example.dart';
import 'package:flutter_example/view_model/view_model.dart';
import 'package:flutter_example/utils/messaging_utils.dart';
import 'package:mindbox/mindbox.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  //https://developers.mindbox.ru/docs/sdk-initialization-flutter
  final config = Configuration(
      domain: "api.mindbox.ru",
      endpointIos: "Mpush-test.FlutterExample.IosApp",
      endpointAndroid: "Mpush-test.FlutterExample.AndroidApp",
      shouldCreateCustomer: true,
      subscribeCustomerIfCreated: true);

  Mindbox.instance.init(configuration: config);

  //https://developers.mindbox.ru/docs/%D0%BC%D0%B5%D1%82%D0%BE%D0%B4%D1%8B-flutter-sdk
  Mindbox.instance.setLogLevel(logLevel: LogLevel.debug);

  ViewModel.requestPermissions();

  ViewModel.chooseInAppCallback(ChooseInappCallback.defaultInAppCallback);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // To display notifications and handle tap callbacks in foreground,
    // use packages like flutter_local_notifications
    print('Got a message whilst in the foreground!');
    print('Full message JSON: ${jsonEncode(message.toMap())}');
    final isMindbox = isMindboxMessage(message);
    print("Is Mindbox message: $isMindbox");

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const Example());

}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main()
  print("Handling a background message");
  print('Full message JSON: ${jsonEncode(message.toMap())}');
  final isMindbox = isMindboxMessage(message);
  print("Is Mindbox message: $isMindbox");
}
