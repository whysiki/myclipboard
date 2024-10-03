import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'app.dart';
import 'package:intl/intl.dart'; // 用于格式化日期时间
import 'package:open_file/open_file.dart'; // 用于打开文件

class ClipboardManager {
  final ClipboardAppState state;
  final Function(VoidCallback) setStateCallback;
  final ValueNotifier<ThemeMode> themeNotifier;

  ClipboardManager(this.state, this.setStateCallback, this.themeNotifier);

  Future<void> loadClipboardHistory() async {
    state.prefs = await SharedPreferences.getInstance();
    setStateCallback(() {
      state.clipboardHistory =
          (state.prefs.getStringList('clipboardHistory') ?? [])
              .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
              .toList();
    });
  }

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
      String? outputPath;

      // 获取当前时间并格式化
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

      if (Platform.isWindows) {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: '选择导出路径',
          fileName: 'clipboard_history_$formattedDate.txt',
        );
      } else if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadDir = Directory('${directory.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          outputPath =
              '${downloadDir.path}/clipboard_history_$formattedDate.txt';
        }
      }

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(
            state.clipboardHistory.map((item) => item['text']).join('\n'));
        if (state.mounted) {
          ScaffoldMessenger.of(state.context).showSnackBar(
            SnackBar(
              content: Text('剪贴板历史已导出到 $outputPath'),
              action: SnackBarAction(
                label: '打开',
                onPressed: () {
                  OpenFile.open(outputPath);
                },
              ),
            ),
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
      themeNotifier.value = state.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme() async {
    setStateCallback(() {
      state.isDarkMode = !state.isDarkMode;
      themeNotifier.value = state.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
    await state.prefs.setBool('isDarkMode', state.isDarkMode);
  }

  void toggleSortOrder() {
    setStateCallback(() {
      state.isDescending = !state.isDescending;
    });
  }
}
