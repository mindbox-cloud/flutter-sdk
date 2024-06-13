
import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/main_page/widgets/buttons_block/buttons_block.dart';
import 'package:flutter_example/view/main_page/widgets/info_block/info_block.dart';
import 'package:shared_preferences/shared_preferences.dart';




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
}

Future<void> _showAlertIfNeeded() async {
  if (!await isAlertShown()) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(

          content: Text('In-App can only be shown once per session'),
          actions: [
            TextButton(
              onPressed: () {
                setAlertShown();
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: MBColors.backgroundColor,
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ButtonsBlock(),
            SizedBox(height: 10),
            InfoBlock(),
          ],
        )),
      ),
    );
  }
}

Future<bool> isAlertShown() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('alertShown') ?? false;
}

Future<void> setAlertShown() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('alertShown', true);
}