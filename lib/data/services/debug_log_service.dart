import 'package:flutter/foundation.dart';

/// TODO(debug): 純除錯用，問題排除後可整支刪除（連同 debug_log_page.dart
/// 以及 home_page.dart 裡呼叫這個檔案／導向除錯頁的那幾行）。
///
/// 輕量級的記憶體內 log 蒐集器，跟 dev.log() 分開存在——dev.log 只有接
/// 開發工具（flutter run / Xcode Console）才看得到，release/TestFlight
/// 版本不一定能看到完整內容。這裡把「這次同步實際發生了什麼」的關鍵事件
/// 額外記一份在記憶體裡，讓 DebugLogPage 可以直接在畫面上列出來，測試時
/// 截圖或複製文字回報即可，不需要接電腦。
class DebugLogService {
  static final List<DebugLogEntry> _entries = [];
  static const _maxEntries = 400;

  /// 每次新增 log 時遞增，DebugLogPage 用它判斷要不要重新整理畫面。
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void log(String tag, String message) {
    _entries.add(DebugLogEntry(time: DateTime.now(), tag: tag, message: message));
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    revision.value++;
  }

  /// 新到舊排序。
  static List<DebugLogEntry> get entries => _entries.reversed.toList();

  static void clear() {
    _entries.clear();
    revision.value++;
  }

  /// 整份轉成純文字，方便複製貼上回報（比截圖更精確，不需要辨識文字）。
  static String exportAsText() {
    final buf = StringBuffer();
    for (final e in entries) {
      buf.writeln('[${e.timeLabel}] ${e.tag}: ${e.message}');
    }
    return buf.toString();
  }
}

class DebugLogEntry {
  final DateTime time;
  final String tag;
  final String message;

  const DebugLogEntry({required this.time, required this.tag, required this.message});

  String get timeLabel {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
