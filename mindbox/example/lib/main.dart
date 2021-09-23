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
  String _sdkVersion = "";

  // Initialization fields
  String domain = "";
  String endpointIos = "";
  String endpointAndroid = "";

  @override
  void initState() {
    super.initState();
    initMindbox();
  }

  Future<void> initMindbox() async {
    String sdkVersion = 'Unknown';

    final configuration = Configuration(
      domain: domain,
      endpointIos: endpointIos,
      endpointAndroid: endpointAndroid,
      subscribeCustomerIfCreated: false,
    );

    try {
      sdkVersion = await Mindbox.instance.sdkVersion;

      setState(() {
        _sdkVersion = sdkVersion;
      });

      await Mindbox.instance.init(configuration: configuration);

    } catch (e) {
      print(e);
    }

    if (!mounted) return;


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
