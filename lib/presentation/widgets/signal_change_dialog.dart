import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/services/signal_change_detector.dart';

class SignalChangeDialog extends StatelessWidget {
  final List<SignalChange> changes;

  const SignalChangeDialog({super.key, required this.changes});

  @override
  Widget build(BuildContext context) {
    final upgrades = changes.where((c) => c.isUpgrade).toList();
    final downgrades = changes.where((c) => c.isDowngrade).toList();
    final firstTime = changes.where((c) => c.isFirstTracking).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 標題列 ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '關注板塊訊號異動',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '以下 ${changes.length} 個關注板塊，自上次開啟後訊號已變化',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── 異動列表 ───────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (upgrades.isNotEmpty) ...[
                    _sectionLabel('✅ 訊號升級', const Color(0xFF1B5E20)),
                    ...upgrades.map(_buildChangeTile),
                    const SizedBox(height: 8),
                  ],
                  if (downgrades.isNotEmpty) ...[
                    _sectionLabel('⚠️ 訊號降級', const Color(0xFFC62828)),
                    ...downgrades.map(_buildChangeTile),
                    const SizedBox(height: 8),
                  ],
                  if (firstTime.isNotEmpty) ...[
                    _sectionLabel('🆕 首次訊號記錄', const Color(0xFF0277BD)),
                    ...firstTime.map(_buildChangeTile),
                  ],
                ],
              ),
            ),
          ),

          // ── 按鈕列 ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('知道了，前往查看'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChangeTile(SignalChange change) {
    Color prevColor = _actionColor(change.previousAction ?? 'neutral');
    Color newColor = _actionColor(change.newAction);

    final directionIcon = change.isFirstTracking
        ? Icons.fiber_new_rounded
        : (change.isUpgrade ? Icons.trending_up_rounded : Icons.trending_down_rounded);
    final directionColor = change.isFirstTracking
        ? const Color(0xFF0277BD)
        : (change.isUpgrade ? const Color(0xFF2E7D32) : const Color(0xFFC62828));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: directionColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: directionColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(directionIcon, size: 16, color: directionColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              change.category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          if (!change.isFirstTracking) ...[
            _actionBadge(change.previousLabel, prevColor),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward, size: 12, color: Color(0xFF9E9E9E)),
            ),
          ],
          _actionBadge(change.newLabel, newColor),
        ],
      ),
    );
  }

  Widget _actionBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'buy': return const Color(0xFF2E7D32);
      case 'hold': return const Color(0xFFF57F17);
      case 'sell': return const Color(0xFFC62828);
      case 'neutral': return const Color(0xFF616161);
      default: return const Color(0xFF616161);
    }
  }
}
