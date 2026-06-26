import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/watchlist/repositories/watchlist_repository.dart';

/// 星號收藏按鈕。
/// 使用 StreamBuilder 訂閱 Drift stream，任何地方取消/加入收藏都會即時同步。
class WatchlistButton extends StatelessWidget {
  final WatchlistRepository repository;
  final String categoryName;
  final double size;

  const WatchlistButton({
    super.key,
    required this.repository,
    required this.categoryName,
    this.size = 22,
  });

  Future<void> _toggle(BuildContext context, bool currentlyWatched) async {
    await repository.toggle(categoryName);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyWatched
                ? '已從觀察清單移除：$categoryName'
                : '已加入觀察清單：$categoryName',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: repository.watchIsWatched(categoryName),
      builder: (context, snapshot) {
        final isWatched = snapshot.data ?? false;
        // 資料尚未到達前顯示佔位避免 layout shift
        if (!snapshot.hasData) {
          return SizedBox(width: size + 8, height: size + 8);
        }
        return GestureDetector(
          onTap: () => _toggle(context, isWatched),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              isWatched ? Icons.star_rounded : Icons.star_border_rounded,
              color: isWatched
                  ? const Color(0xFFF9A825)
                  : Colors.grey.shade400,
              size: size,
            ),
          ),
        );
      },
    );
  }
}
