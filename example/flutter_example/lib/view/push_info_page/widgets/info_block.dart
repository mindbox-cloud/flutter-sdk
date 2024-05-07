import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/main_page/widgets/info_block/ingo_block_line.dart';
import 'package:flutter_example/view_model/view_model.dart';

class InfoBlock extends StatefulWidget {
  const InfoBlock({
    super.key,
  });

  @override
  State<InfoBlock> createState() => _InfoBlockState();
}

class _InfoBlockState extends State<InfoBlock> {



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
                InfoBlockLine(title: 'Link', data: ViewModel.pushLink),
                const Divider(
                  color: MBColors.deviderColor,
                ),
                const SizedBox(height: 3),
                InfoBlockLine(title: 'Payload', data: ViewModel.pushPayload),

              ],
            ),
          ),
        ),
      ],
    );
  }
}
