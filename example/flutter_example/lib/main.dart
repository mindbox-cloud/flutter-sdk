
import 'package:flutter/material.dart';
import 'package:flutter_example/view/main_page.dart';
import 'package:mindbox/mindbox.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = Configuration(
      domain: "api.mindbox.ru",
      endpointIos: "Mpush-test.FlutterExample.IosApp",
      endpointAndroid: "Mpush-test.FlutterExample.AndroidApp",
      shouldCreateCustomer: true,
      subscribeCustomerIfCreated: true);

  Mindbox.instance.init(configuration: config);
  runApp(const Example());

  requestPermissions();

  Mindbox.instance.registerInAppCallback(callbacks: [
    CustomInAppCallback((String id, String redirectUrl, String payload) {
      print('CustomInAppCallback onClick');
    }, (String id) {
      print('CustomInAppCallback onDismiss');
    })
  ]);
}


  Future<void> requestPermissions() async {
    Permission.notification.isDenied.then((bool isGranted) async {
      print('==DEBUG==: Requesting permission.');
      
      final PermissionStatus status = await Permission.notification.request();

      print('==DEBUG==: New status: $status');
      Mindbox.instance
          .updateNotificationPermissionStatus(granted: status.isGranted);
    });
  }