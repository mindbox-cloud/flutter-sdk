import 'package:flutter/material.dart';
import 'package:flutter_example/view/main_page.dart';
import 'package:mindbox/mindbox.dart';

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

  Mindbox.instance.registerInAppCallback(callbacks: [
    CustomInAppCallback((String id, String redirectUrl, String payload) {
      print('CustomInAppCallback onClick');
    }, (String id) {
      print('CustomInAppCallback onDismiss');
    })
  ]);1234
