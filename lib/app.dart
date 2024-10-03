import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'clipboard_manager.dart';

class ClipboardApp extends StatefulWidget {
  const ClipboardApp({super.key});

  @override
  ClipboardAppState createState() => ClipboardAppState();
}

class ClipboardAppState extends State<ClipboardApp> {
  List<Map<String, dynamic>> clipboardHistory = [];
  late SharedPreferences prefs;
  Timer? clipboardTimer;
  String searchQuery = '';
  bool isDarkMode = true;
  bool isDescending = true;
  late ClipboardManager clipboardManager;

  @override
  void initState() {
    super.initState();
    clipboardManager = ClipboardManager(this, setState);
    clipboardManager.loadPreferences();
    clipboardManager.loadClipboardHistory();
    clipboardManager.startClipboardMonitor();
  }

  @override
  void dispose() {
    clipboardTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = clipboardHistory
        .where((item) => item['text'].contains(searchQuery))
        .toList()
      ..sort((a, b) => isDescending
          ? b['timestamp'].compareTo(a['timestamp'])
          : a['timestamp'].compareTo(b['timestamp']));

    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索剪贴板历史...',
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: clipboardManager.toggleTheme,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: clipboardManager.clearClipboardHistory,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: clipboardManager.exportClipboardHistory,
            ),
            IconButton(
              icon: Icon(
                  isDescending ? Icons.arrow_downward : Icons.arrow_upward),
              onPressed: clipboardManager.toggleSortOrder,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: filteredHistory.isEmpty
              ? const Center(child: Text('剪贴板历史为空'))
              : ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(filteredHistory[index]['text']),
                        subtitle: Text(filteredHistory[index]['timestamp']),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => clipboardManager
                              .copyToClipboard(filteredHistory[index]['text']),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
