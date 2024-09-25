import 'dart:io';

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
  String sdkVerson = '';
  String token = '';
  String deviceUUID = '';
  String tokenLabel = 'Token';

  @override
  void initState() {
    ViewModel.getSDKVersion((value) {
      sdkVerson = value;
      setState(() {});
    });
    ViewModel.getToken((value) {
      token = value;
      if (Platform.isAndroid) {
        if (value.toString().contains(":")) {
          tokenLabel = "Firebase Cloud Messaging token";
        } else {
          tokenLabel = "Huawei Push Kit token";
        }
      } else if (Platform.isIOS) {
        tokenLabel = "APNS token";
      }
      setState(() {});
    });
    ViewModel.getDeviceUUID((value) {
      deviceUUID = value;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 350,
          height: 190,
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
                      'Data from SDK:',
                      style: TextStyle(color: MBColors.textColor, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                InfoBlockLine(title: 'SDK version', data: sdkVerson),
                const Divider(
                  color: MBColors.deviderColor,
                ),
                const SizedBox(height: 3),
                InfoBlockLine(title: tokenLabel, data: token),
                const Divider(
                  color: MBColors.deviderColor,
                ),
                InfoBlockLine(title: 'Device UUID', data: deviceUUID),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
