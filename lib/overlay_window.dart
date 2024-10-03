import 'package:flutter/material.dart';

class OverlayWindow extends StatelessWidget {
  const OverlayWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 200,
            height: 200,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Overlay Window'),
                ElevatedButton(
                  onPressed: () {
                    // Close the overlay window
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
