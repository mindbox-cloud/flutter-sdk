import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/main_page/widgets/buttons_block/buttons_block_line.dart';
import 'package:flutter_example/view_model/view_model.dart';

class ButtonsBlock extends StatelessWidget {
  const ButtonsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 350,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: MBColors.blockBackgroundColor,
          ),
          child: const Padding(
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ButtonsBlockLine(
                  title: 'Async operation',
                  getInapp: ViewModel.asyncOperation,
                ),
                Divider(
                  color: MBColors.deviderColor,
                ),
                ButtonsBlockLine(
                  title: 'Sync operation',
                  getInapp: ViewModel.syncOperation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

