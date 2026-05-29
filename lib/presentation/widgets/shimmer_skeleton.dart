import 'package:flutter/material.dart';

/// 泛用型高效微光骨架屏元件
class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 🚀 使用 1.2 秒的循環打光動畫，維持流暢視覺感
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // 動態計算掃描漸層的起訖點
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 模擬主頁卡片的骨架屏排版
class MainSectionSkeleton extends StatelessWidget {
  const MainSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerSkeleton(width: 140, height: 28),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const ShimmerSkeleton(
                  width: 62,
                  height: 62,
                  borderRadius: KaBorderRadius.r20,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerSkeleton(width: 120, height: 22),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const ShimmerSkeleton(width: 60, height: 16),
                          const SizedBox(width: 8),
                          const ShimmerSkeleton(width: 50, height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                const ShimmerSkeleton(width: 70, height: 45),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class KaBorderRadius {
  static const BorderRadius r20 = BorderRadius.all(Radius.circular(20));
}
