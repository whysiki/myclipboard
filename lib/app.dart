import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'clipboard_manager.dart';
import 'package:expandable_text/expandable_text.dart';

class ClipboardApp extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  //required 关键字表示这个参数是必需的，调用构造函数时必须提供这个参数。

  const ClipboardApp({super.key, required this.themeNotifier});

  @override
  ClipboardAppState createState() => ClipboardAppState();
}

class ClipboardAppState extends State<ClipboardApp> {
  List<Map<String, dynamic>> clipboardHistory = [];
  late SharedPreferences prefs;
  Timer? clipboardTimer;
  String searchQuery = ''; //搜索关键字
  bool isDarkMode = true;
  bool isDescending = true;
  late ClipboardManager clipboardManager;

  @override
  void initState() {
    super.initState();
    clipboardManager = ClipboardManager(this, setState, widget.themeNotifier);
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

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索剪贴板历史...',
              border: InputBorder.none,
              filled: true,
              // fillColor:
              // const Color.fromARGB(255, 172, 172, 172).withOpacity(0.1),
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1), // 根据主题模式设置背景颜色
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0), // 设置圆角边框
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0), // 设置圆角边框
                borderSide: BorderSide.none,
              ),
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
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: clipboardManager.exportClipboardHistory,
          ),
          IconButton(
            icon:
                Icon(isDescending ? Icons.arrow_downward : Icons.arrow_upward),
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
                      title: ExpandableText(
                        filteredHistory[index]['text'],
                        expandText: '展开',
                        collapseText: '收起',
                        maxLines: 4,
                        linkColor: Colors.blue,
                      ),
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
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('你确定要清空剪贴板历史吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确认'),
              onPressed: () {
                clipboardManager.clearClipboardHistory();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
