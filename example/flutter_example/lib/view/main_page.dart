
import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/widgets/buttons_block/buttons_block.dart';
import 'package:flutter_example/view/widgets/info_block/info_block.dart';

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => const MyHomePage(),
      },
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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



