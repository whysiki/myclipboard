import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'app.dart';

class ClipboardManager {
  // final 关键字用于声明 ClipboardManager 类的两个成员变量 state 和 setStateCallback，表示它们在被赋值后不能再被更改。
  final ClipboardAppState state;
  final Function(VoidCallback) setStateCallback;

  ClipboardManager(this.state, this.setStateCallback);

  Future<void> loadClipboardHistory() async {
    state.prefs = await SharedPreferences.getInstance();
    setStateCallback(() {
      state.clipboardHistory =
          (state.prefs.getStringList('clipboardHistory') ?? [])
              .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
              .toList();
    });
  }

  // Future<void> 表示一个异步操作，该操作不会返回任何值。
  // Future 是 Dart 中用于处理异步编程的核心类，它表示一个可能在将来某个时间点完成的计算。

  Future<void> saveClipboardHistory() async {
    await state.prefs.setStringList('clipboardHistory',
        state.clipboardHistory.map((item) => jsonEncode(item)).toList());
  }

  void startClipboardMonitor() {
    state.clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      getClipboardContent();
    });
  }

  Future<void> getClipboardContent() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        if (!state.clipboardHistory.any((item) => item['text'] == data.text)) {
          if (state.mounted) {
            setStateCallback(() {
              state.clipboardHistory.add(
                  {'text': data.text!, 'timestamp': DateTime.now().toString()});
              saveClipboardHistory();
            });
          }
        }
      }
    } catch (e) {
      if (state.mounted) {
        ScaffoldMessenger.of(state.context).showSnackBar(
          SnackBar(content: Text('获取剪贴板内容失败: $e')),
        );
      }
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(content: Text('已复制到剪贴板: $text')),
    );
  }

  void clearClipboardHistory() {
    if (state.mounted) {
      setStateCallback(() {
        state.clipboardHistory.clear();
        saveClipboardHistory();
      });
    }
  }

  Future<void> exportClipboardHistory() async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '选择导出路径',
        fileName: 'clipboard_history.txt',
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(
            state.clipboardHistory.map((item) => item['text']).join('\n'));
        if (state.mounted) {
          ScaffoldMessenger.of(state.context).showSnackBar(
            SnackBar(content: Text('剪贴板历史已导出到 $outputPath')),
          );
        }
      } else {
        if (state.mounted) {
          ScaffoldMessenger.of(state.context).showSnackBar(
            const SnackBar(content: Text('导出取消')),
          );
        }
      }
    } catch (e) {
      if (state.mounted) {
        ScaffoldMessenger.of(state.context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> loadPreferences() async {
    state.prefs = await SharedPreferences.getInstance();
    setStateCallback(() {
      state.isDarkMode = state.prefs.getBool('isDarkMode') ?? true;
    });
  }

  void toggleTheme() async {
    setStateCallback(() {
      state.isDarkMode = !state.isDarkMode;
    });
    await state.prefs.setBool('isDarkMode', state.isDarkMode);
  }

  void toggleSortOrder() {
    setStateCallback(() {
      state.isDescending = !state.isDescending;
    });
  }
}
