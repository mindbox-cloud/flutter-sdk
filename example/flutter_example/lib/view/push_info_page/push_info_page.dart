import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/push_info_page/widgets/info_block.dart';

class PushInfoPage extends StatelessWidget {
  final String link;
  final dynamic payload;

  const PushInfoPage({super.key, required this.link, required this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MBColors.backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InfoBlock(link: link, payload: payload),
          ],
        ),
      ),
    );
  }
}