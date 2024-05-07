import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';

class ButtonsBlockLine extends StatelessWidget {
  const ButtonsBlockLine({
    super.key,
    required this.title,
    required this.getInapp,
  });

  final String title;
  final Function getInapp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: MBColors.textColor,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: MBColors.buttonColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkResponse(
              radius: 20,
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                getInapp();
              },
              child: const SizedBox(
                width: 120,
                height: 30,
                child: Center(
                  child: Text(
                    'Show In-App',
                    style: TextStyle(
                      color: MBColors.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
