import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(ClipboardApp());
}

class ClipboardApp extends StatefulWidget {
  @override
  _ClipboardAppState createState() => _ClipboardAppState();
}

class _ClipboardAppState extends State<ClipboardApp> {
  List<Map<String, dynamic>> clipboardHistory = [];
  late SharedPreferences prefs;
  Timer? clipboardTimer;
  String searchQuery = '';
  bool isDarkMode = true;
  bool isDescending = true; // 新增变量

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadClipboardHistory();
    _startClipboardMonitor();
  }

  @override
  void dispose() {
    clipboardTimer?.cancel();
    super.dispose();
  }

  _loadClipboardHistory() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      clipboardHistory = (prefs.getStringList('clipboardHistory') ?? [])
          .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
          .toList();
    });
  }

  _saveClipboardHistory() async {
    await prefs.setStringList('clipboardHistory',
        clipboardHistory.map((item) => jsonEncode(item)).toList());
  }

  void _startClipboardMonitor() {
    clipboardTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _getClipboardContent();
    });
  }

  Future<void> _getClipboardContent() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        if (!clipboardHistory.any((item) => item['text'] == data.text)) {
          setState(() {
            clipboardHistory.add(
                {'text': data.text!, 'timestamp': DateTime.now().toString()});
            _saveClipboardHistory();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取剪贴板内容失败: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制到剪贴板: $text')),
    );
  }

  void _clearClipboardHistory() {
    setState(() {
      clipboardHistory.clear();
      _saveClipboardHistory();
    });
  }

  Future<void> _exportClipboardHistory() async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '选择导出路径',
        fileName: 'clipboard_history.txt',
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(
            clipboardHistory.map((item) => item['text']).join('\n'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('剪贴板历史已导出到 $outputPath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出取消')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  _toggleTheme() async {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void _toggleSortOrder() {
    setState(() {
      isDescending = !isDescending;
    });
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
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
              icon: Icon(Icons.brightness_6),
              onPressed: _toggleTheme,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _clearClipboardHistory,
            ),
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _exportClipboardHistory,
            ),
            IconButton(
              icon: Icon(
                  isDescending ? Icons.arrow_downward : Icons.arrow_upward),
              onPressed: _toggleSortOrder,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: filteredHistory.isEmpty
              ? Center(child: Text('剪贴板历史为空'))
              : ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(filteredHistory[index]['text']),
                        subtitle: Text(filteredHistory[index]['timestamp']),
                        trailing: IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () =>
                              _copyToClipboard(filteredHistory[index]['text']),
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
