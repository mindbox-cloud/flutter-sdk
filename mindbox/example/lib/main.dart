import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mindbox/mindbox.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _sdkVersion = '';

  @override
  void initState() {
    super.initState();
    getSdkVersion();
  }

  Future<void> getSdkVersion() async {
    final String sdkVersion = await Mindbox.instance.nativeSdkVersion;

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
          child: Text('Running on: $_sdkVersion'),
        ),
      ),
    );
  }
}
