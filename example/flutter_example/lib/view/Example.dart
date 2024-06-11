import 'package:flutter/material.dart';
import 'package:flutter_example/view/main_page/main_page.dart';
import 'package:flutter_example/view/push_info_page/push_info_page.dart';
import 'package:flutter_example/view/notification_center_page/notification_center_page.dart';

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => const MyHomePage(),
        '/push_info': (context) => const PushInfoPage(),
        '/notification_center': (context) => const NotificationCenterScreen(),
      },
    );
  }
}