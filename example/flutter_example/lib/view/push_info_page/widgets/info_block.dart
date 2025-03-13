import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/main_page/widgets/info_block/ingo_block_line.dart';

class InfoBlock extends StatelessWidget {

  const InfoBlock({super.key, required this.link, required this.payload});
  final String link;
  final dynamic payload;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 350,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: MBColors.blockBackgroundColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Data from push:',
                      style: TextStyle(color: MBColors.textColor, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                InfoBlockLine(title: 'Link', data: link),
                const Divider(
                  color: MBColors.deviderColor,
                ),
                const SizedBox(height: 3),
                InfoBlockLine(title: 'Payload', data: payload),

              ],
            ),
          ),
        ),
      ],
    );
  }
}
