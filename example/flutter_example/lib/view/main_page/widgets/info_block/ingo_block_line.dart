import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/assets/MBColors.dart';

class InfoBlockLine extends StatelessWidget {
  const InfoBlockLine({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        child: InkResponse(
          radius: 520,
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Clipboard.setData(ClipboardData(text: data));
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: MBColors.textColor, fontSize: 8),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      data,
                      style: const TextStyle(color: MBColors.textColor, fontSize: 12),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
