
import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/main_page/widgets/buttons_block/buttons_block.dart';
import 'package:flutter_example/view/main_page/widgets/info_block/info_block.dart';
import 'package:flutter_example/view/main_page/widgets/buttons_block/button_nc.dart';
import 'package:flutter_example/view/notification_center_page/notification_center_page.dart';
import 'package:flutter_example/view_model/view_model.dart';
import 'package:mindbox/mindbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../push_info_page/push_info_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
    _showAlertIfNeeded();
    // Please note: if the context is not initialized at the time of
    // receiving data from the push, then navigation will not work
    Mindbox.instance.onPushClickReceived((link, payload) {
      _handlePushNotification(link, payload);
    });
  }

  void _handlePushNotification(String link, dynamic payload) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PushInfoPage(link: link, payload: payload),
      ),
    );
  }

  Future<void> _showAlertIfNeeded() async {
    if (!await isAlertShown()) {
      if (!mounted)
        { return; }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('In-App can only be shown once per session'),
            actions: [
              TextButton(
                onPressed: () {
                  setAlertShown();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: MBColors.backgroundColor,
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ButtonsBlock(),
            const SizedBox(height: 10),
            const InfoBlock(),
            const SizedBox(height: 10),
            CustomButton(
              title: 'Go to notification center',
              onPressed: () {
                //send operation mobile mobileapp.NCOpen
                ViewModel.asyncOperationNCOpen();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                );
              },
            ),
          ],
        )),
      ),
    );
  }
}

Future<bool> isAlertShown() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('alertShown') ?? false;
}

Future<void> setAlertShown() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('alertShown', true);
}