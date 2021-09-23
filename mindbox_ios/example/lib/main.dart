import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mindbox_ios/mindbox_ios.dart';

import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// When using the iOs plugin directly it is mandatory to register
  /// the plugin as default instance as part of initializing the app.
  MindboxIosPlatform.registerPlatform();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _sdkVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String sdkVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      sdkVersion =
      await MindboxPlatform.instance.sdkVersion;
    } on PlatformException {
      sdkVersion = 'Failed to get SDK version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _sdkVersion = sdkVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mindbox SDK example app'),
        ),
        body: Center(
          child: Text('Running on: $_sdkVersion\n'),
        ),
      ),
    );
  }
}
