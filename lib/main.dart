import 'package:flutter/material.dart';
import 'app.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
// import 'overlay_window.dart';

// void main() {
//   runApp(const ClipboardApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 检查并请求悬浮窗权限
  bool permissionGranted = await FlutterOverlayWindow.isPermissionGranted();
  if (!permissionGranted) {
    permissionGranted = (await FlutterOverlayWindow.requestPermission())!;
  }

  if (permissionGranted) {
    runApp(const MyApp());
  } else {
    runApp(const PermissionDeniedApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ClipboardApp(),
    );
  }
}

class PermissionDeniedApp extends StatelessWidget {
  const PermissionDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Permission Denied'),
        ),
        body: const Center(
          child: Text('Overlay permission is required to run this app.'),
        ),
      ),
    );
  }
}
