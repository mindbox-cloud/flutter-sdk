import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/features/main_page/widgets/buttons_block/buttons_block_line.dart';
import 'package:mindbox/mindbox.dart';

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
                  getInapp: asyncOperation,
                ),
                Divider(
                  color: Color.fromARGB(255, 74, 74, 74),
                ),
                ButtonsBlockLine(
                  title: 'Sync operation',
                  getInapp: syncOperation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

void syncOperation() {
  print('syncOperation123');
  Mindbox.instance.executeSyncOperation(
    operationSystemName: 'APIMethodForReleaseExampleIos',
    operationBody: {
      "viewProduct": {
        "product": {
          "ids": {"website": "1"}
        }
      }
    },
    onSuccess: (data) {},
    onError: (error) {},
  );
}

void asyncOperation() {
  print('asyncOperation');
  Mindbox.instance.executeAsyncOperation(
      operationSystemName: "APIMethodForReleaseExampleIos",
      operationBody: {
        "viewProduct": {
          "product": {
            "ids": {"website": "2"}
          }
        }
      });
}
