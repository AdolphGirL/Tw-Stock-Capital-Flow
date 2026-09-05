import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tw_stock_capital_flow/data/services/debug_log_service.dart';

/// TODO(debug): 純除錯用，問題排除後可整支刪除。
///
/// 顯示 DebugLogService 蒐集到的同步/抓取事件，新到舊排序。
/// 「複製全部」比截圖更精確（不需要辨識文字），優先用這個回報。
class DebugLogPage extends StatefulWidget {
  /// 一鍵重置：清空本地快照＋SQLite 市場數據歷史，強制重新抓取並重算。
  /// 由 main.dart 的 `_resetAndResync` 一路傳下來；為 null 時不顯示重置按鈕。
  final Future<String> Function()? onResetAndResync;

  const DebugLogPage({super.key, this.onResetAndResync});

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  bool _isResetting = false;

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

  Future<void> _confirmAndReset() async {
    if (widget.onResetAndResync == null || _isResetting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('一鍵重置並重新抓取', style: TextStyle(color: Colors.white)),
        content: const Text(
          '會先強制重新向 TWSE/TPEX 抓取一次今日資料，確定抓取成功後才「全部'
          '清空」本機資料：SQLite 全部資料表（板塊/主流/生命週期/輪動歷史，'
          '以及觀察清單、訊號比對紀錄）與本機所有 JSON 快取（股票快照、分析'
          '結果快取、三大法人與融資融券歷史），只保留剛抓到的「今天」資料重'
          '新寫回並重新計算。若這次抓取失敗，本機既有資料不會被動到。\n\n'
          '清空後只剩今天一天資料，需要多天歷史窗口的指標（如延續力、異常偵'
          '測 Z-score）會在接下來幾天內因樣本不足而暫時失準，需等 App 正常使'
          '用幾天重新累積資料才會恢復；觀察清單收藏與訊號通知比對基準也會一'
          '併清空、需重新設定。\n\n此動作無法復原，確定要繼續嗎？',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('確定重置'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResetting = true);
    try {
      final message = await widget.onResetAndResync!();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('重置失敗：$e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
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
          if (widget.onResetAndResync != null)
            IconButton(
              tooltip: '一鍵重置並重新抓取',
              icon: _isResetting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                    )
                  : const Icon(Icons.restart_alt_rounded, color: Colors.redAccent),
              onPressed: _isResetting ? null : _confirmAndReset,
            ),
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
