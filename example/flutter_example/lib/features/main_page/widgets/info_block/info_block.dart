import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/features/main_page/widgets/info_block/ingo_block_line.dart';
import 'package:mindbox/mindbox.dart';

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
  @override
  void initState() {
    Mindbox.instance.nativeSdkVersion.then((value) {
      print('verson');
      sdkVerson = value;
      setState(() {});
    });
    Mindbox.instance.getDeviceUUID((value) {
      print(value);
      deviceUUID = value;
      setState(() {});
    });
    Mindbox.instance.getToken((value) {
      print(value);
      token = value;
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
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                InfoBlockLine(title: 'SDK version', data: sdkVerson),
                const Divider(
                  color: MBColors.deviderColor,
                ),
                const SizedBox(height: 3),
                InfoBlockLine(title: 'PNS token', data: token),
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
