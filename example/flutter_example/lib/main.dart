import 'package:flutter/material.dart';
import 'package:flutter_example/view/main_page.dart';
import 'package:flutter_example/view_model/view_model.dart';
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

  Mindbox.instance.setLogLevel(logLevel: LogLevel.debug);

  ViewModel.onPushClickReceived();

  ViewModel.requestPermissions();

  ViewModel.chooseInAppCallback(ChooseInappCallback.customInAppCallback);

  runApp(const Example());
}
