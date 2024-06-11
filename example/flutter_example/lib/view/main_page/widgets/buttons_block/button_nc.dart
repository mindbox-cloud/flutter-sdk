import 'package:flutter/material.dart';
import 'package:flutter_example/assets/MBColors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: MBColors.buttonColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkResponse(
            radius: 20,
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: MBColors.textColor,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
