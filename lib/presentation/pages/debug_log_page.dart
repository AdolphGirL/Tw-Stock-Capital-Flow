import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tw_stock_capital_flow/data/services/debug_log_service.dart';

/// TODO(debug): 純除錯用，問題排除後可整支刪除。
///
/// 顯示 DebugLogService 蒐集到的同步/抓取事件，新到舊排序。
/// 「複製全部」比截圖更精確（不需要辨識文字），優先用這個回報。
class DebugLogPage extends StatefulWidget {
  const DebugLogPage({super.key});

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  @override
  void initState() {
    super.initState();
    DebugLogService.revision.addListener(_onChanged);
  }

  @override
  void dispose() {
    DebugLogService.revision.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = DebugLogService.entries;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('除錯 Log（僅供測試）'),
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: '複製全部',
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: entries.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: DebugLogService.exportAsText()),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已複製全部 log 到剪貼簿'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            tooltip: '清除',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: entries.isEmpty
                ? null
                : () => setState(() => DebugLogService.clear()),
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                '目前沒有任何紀錄\n請先觸發一次同步（開啟 App 或按下重新整理）',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 12),
              itemBuilder: (context, index) {
                final e = entries[index];
                return _buildEntry(e);
              },
            ),
    );
  }

  Widget _buildEntry(DebugLogEntry e) {
    final tagColor = _colorForTag(e.tag);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              e.timeLabel,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                e.tag,
                style: TextStyle(
                  color: tagColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SelectableText(
          e.message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontFamily: 'monospace',
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Color _colorForTag(String tag) {
    if (tag.contains('上市') || tag.contains('Listed')) return const Color(0xFFE57373);
    if (tag.contains('上櫃') || tag.contains('OTC')) return const Color(0xFF64B5F6);
    if (tag.contains('SQLite')) return const Color(0xFF81C784);
    if (tag.contains('Sync')) return const Color(0xFFFFB74D);
    return const Color(0xFFB39DDB);
  }
}
