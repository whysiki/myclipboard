import 'dart:convert'; //用于 JSON 编码和解码。
import 'package:flutter/material.dart'; //提供 Flutter 的 Material Design 组件。
import 'package:flutter/services.dart'; //用于与平台服务（如剪贴板）交互。
import 'package:shared_preferences/shared_preferences.dart'; //用于持久化存储简单数据。
import 'package:file_picker/file_picker.dart'; //用于文件选择和保存。window
import 'dart:async'; //提供异步编程支持。
import 'dart:io'; //提供文件和其他 I/O 支持

void main() {
  runApp(const ClipboardApp()); //// Flutter 内置函数，启动应用。
}

class ClipboardApp extends StatefulWidget {
  const ClipboardApp({super.key});

  //// Flutter 内置类，用于创建有状态的组件。
  ///createState() 不是内置函数，而是 Flutter 框架中 StatefulWidget 类的一个抽象方法。它用于创建与 StatefulWidget 关联的状态对象。
  @override
  ClipboardAppState createState() => ClipboardAppState(); //// 创建组件的状态。
}

class ClipboardAppState extends State<ClipboardApp> {
  //// Flutter 内置类，表示组件的状态。
  List<Map<String, dynamic>> clipboardHistory = []; // 自定义变量，存储剪贴板历史记录。
  late SharedPreferences prefs; // 自定义变量，用于访问共享偏好设置。
  Timer? clipboardTimer; // 自定义变量，定时器，用于定期检查剪贴板内容。
  String searchQuery = ''; // 自定义变量，搜索查询字符串。
  bool isDarkMode = true; // 自定义变量，是否启用暗模式。
  bool isDescending = true; // 自定义变量，是否按降序排序。

  @override
  void initState() {
    // Flutter 内置方法，初始化状态。
    super.initState(); // 调用父类方法。
    loadPreferences(); // 自定义方法，加载偏好设置。
    _loadClipboardHistory(); // 自定义方法，加载剪贴板历史。
    _startClipboardMonitor(); // 自定义方法，启动剪贴板监视器。
  }

  @override
  void dispose() {
    // Flutter 内置方法，释放资源。
    clipboardTimer?.cancel(); // 取消定时器。
    super.dispose(); // 调用父类方法。
  }

  _loadClipboardHistory() async {
    // 自定义方法，加载剪贴板历史。
    prefs = await SharedPreferences.getInstance(); // 获取共享偏好设置实例。
    setState(() {
      clipboardHistory =
          (prefs.getStringList('clipboardHistory') ?? []) // 从共享偏好设置加载剪贴板历史。
              .map((item) =>
                  Map<String, dynamic>.from(jsonDecode(item))) // 解码 JSON 字符串。
              .toList();
    });
  }

  _saveClipboardHistory() async {
    // 自定义方法，保存剪贴板历史。
    //Saves a list of strings [value] to persistent storage in the background.
    await prefs.setStringList(
        'clipboardHistory',
        clipboardHistory
            .map((item) => jsonEncode(item))
            .toList()); // 编码为 JSON 字符串并保存到共享偏好设置。
  }

  void _startClipboardMonitor() {
    // 自定义方法，启动剪贴板监视器。
    clipboardTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _getClipboardContent(); // 每隔 2 秒检查一次剪贴板内容。
    });
  }

  Future<void> _getClipboardContent() async {
    // 自定义方法，获取剪贴板内容。
    try {
      // 获取剪贴板内容
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      // 如果剪贴板内容不为空，且不在历史记录中，则添加到历史记录
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        if (!clipboardHistory.any((item) => item['text'] == data.text)) {
          if (mounted) {
            setState(() {
              clipboardHistory.add({
                'text': data.text!,
                'timestamp': DateTime.now().toString()
              }); // 添加到剪贴板历史。
              _saveClipboardHistory(); // 保存剪贴板历史。
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // 显示错误提示。
          SnackBar(content: Text('获取剪贴板内容失败: $e')),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    // 自定义方法，复制到剪贴板。
    Clipboard.setData(ClipboardData(text: text)); // 设置剪贴板内容。
    ScaffoldMessenger.of(context).showSnackBar(
      // 显示提示。
      SnackBar(content: Text('已复制到剪贴板: $text')),
    );
  }

  void _clearClipboardHistory() {
    // 自定义方法，清除剪贴板历史。
    if (mounted) {
      setState(() {
        clipboardHistory.clear(); // 清空剪贴板历史。
        _saveClipboardHistory(); // 保存剪贴板历史。
      });
    }
  }

  Future<void> _exportClipboardHistory() async {
    // 自定义方法，导出剪贴板历史。
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '选择导出路径',
        fileName: 'clipboard_history.txt',
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(
            clipboardHistory.map((item) => item['text']).join('\n'));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('剪贴板历史已导出到 $outputPath')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出取消')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  loadPreferences() async {
    // 自定义方法，加载偏好设置。
    prefs = await SharedPreferences.getInstance(); // 获取共享偏好设置实例。
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? true; // 加载暗模式设置。
    });
  }

  toggleTheme() async {
    // 自定义方法，切换主题。
    setState(() {
      isDarkMode = !isDarkMode;
    });
    await prefs.setBool('isDarkMode', isDarkMode); // 保存暗模式设置。
  }

  void toggleSortOrder() {
    // 自定义方法，切换排序顺序。
    setState(() {
      isDescending = !isDescending; // 切换排序顺序。
    });
  }

  @override
  Widget build(BuildContext context) {
    // Flutter 内置方法，用于构建 UI。
    final filteredHistory = clipboardHistory
        .where((item) => item['text'].contains(searchQuery))
        .toList()
      ..sort((a, b) => isDescending
          ? b['timestamp'].compareTo(a['timestamp'])
          : a['timestamp'].compareTo(b['timestamp']));

    return MaterialApp(
      // Flutter 内置组件，表示应用的根组件。
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode:
          isDarkMode ? ThemeMode.dark : ThemeMode.light, // Flutter 内置枚举，设置主题模式。
      home: Scaffold(
        // Flutter 内置组件，表示页面结构。
        appBar: AppBar(
          // Flutter 内置组件，表示应用栏。
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                // Flutter 内置组件，设置输入框的装饰。
                hintText: '搜索剪贴板历史...', // 提示文本。
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (value) {
                // 输入框内容变化时的回调。
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          actions: [
            // 应用栏中的操作按钮。
            IconButton(
              // Flutter 内置组件，表示图标按钮。
              icon: const Icon(Icons.brightness_6), // 设置按钮图标。
              onPressed: toggleTheme, // 按钮点击时的回调。
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearClipboardHistory,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportClipboardHistory,
            ),
            IconButton(
              icon: Icon(
                  isDescending ? Icons.arrow_downward : Icons.arrow_upward),
              onPressed: toggleSortOrder,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: filteredHistory.isEmpty
              ? const Center(child: Text('剪贴板历史为空')) // Flutter 内置组件，表示居中的文本。
              : ListView.builder(
                  // Flutter 内置组件，表示可滚动的列表。
                  itemCount: filteredHistory.length, // 列表项的数量。
                  itemBuilder: (context, index) {
                    // 构建列表项的回调。
                    return Card(
                      // Flutter 内置组件，表示卡片。
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0), // 设置卡片的外边距。
                      child: ListTile(
                        // Flutter 内置组件，表示列表项。
                        title: Text(filteredHistory[index]['text']), // 列表项的标题。
                        subtitle: Text(filteredHistory[index]['timestamp']),
                        trailing: IconButton(
                          // 列表项的尾部按钮。
                          icon: const Icon(Icons.copy), // 设置按钮图标。
                          onPressed: () => _copyToClipboard(
                              filteredHistory[index]['text']), // 按钮点击时的回调。
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
