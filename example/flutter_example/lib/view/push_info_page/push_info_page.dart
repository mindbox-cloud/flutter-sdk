import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/push_info_page/widgets/info_block.dart';


class PushInfoPage extends StatefulWidget {
  const PushInfoPage({super.key});

  @override
  State<PushInfoPage> createState() => _PushInfoPage();
}

class _PushInfoPage extends State<PushInfoPage> {
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
            InfoBlock()
          ],
        )),
      ),
    );
  }
}
