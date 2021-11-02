import 'package:flutter/material.dart';
import 'dart:async';

import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// When using the Android plugin directly it is mandatory to register
  /// the plugin as default instance as part of initializing the app.
  MindboxAndroidPlatform.registerPlatform();

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

  Future<void> initPlatformState() async {
    String sdkVersion = await MindboxPlatform.instance.sdkVersion;

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
