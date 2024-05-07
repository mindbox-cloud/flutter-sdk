import 'package:flutter/material.dart';
import 'package:flutter_example/view/Example.dart';
import 'package:flutter_example/view_model/view_model.dart';
import 'package:mindbox/mindbox.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  ViewModel.chooseInAppCallback(ChooseInappCallback.customInAppCallback);

  runApp(const Example());

  ViewModel.onPushClickReceived();
}
