import 'package:flutter/material.dart';

class TrueCallerOverlay extends StatelessWidget {
  const TrueCallerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 300, // 放大宽度
          height: 300, // 放大高度
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.paste, color: Colors.white, size: 40), // 更换图标并放大
        ),
      ),
    );
  }
}
