import 'package:flutter/material.dart';

/// Advanced skeleton loader with shimmer effect (2025 loading UX best practice)
class AdvancedSkeletonLoader extends StatefulWidget {
  const AdvancedSkeletonLoader({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  @override
  State<AdvancedSkeletonLoader> createState() => _AdvancedSkeletonLoaderState();
}

class _AdvancedSkeletonLoaderState extends State<AdvancedSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Skeleton box placeholder
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton circle (for avatars)
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 48.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey[800] : Colors.grey[300],
      ),
    );
  }
}

/// Skeleton line (for text)
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 16.0,
  });

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// Skeleton card for list items
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonCircle(size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: MediaQuery.of(context).size.width * 0.6),
                    const SizedBox(height: 8),
                    SkeletonLine(width: MediaQuery.of(context).size.width * 0.4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(height: 120, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton list view
class SkeletonListView extends StatelessWidget {
  const SkeletonListView({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AdvancedSkeletonLoader(
      child: ListView.builder(
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => const SkeletonCard(),
      ),
    );
  }
}

/// Skeleton grid view
class SkeletonGridView extends StatelessWidget {
  const SkeletonGridView({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  final int itemCount;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return AdvancedSkeletonLoader(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => const SkeletonBox(
          borderRadius: 16,
        ),
      ),
    );
  }
}

/// Skeleton for lesson card
class SkeletonLessonCard extends StatelessWidget {
  const SkeletonLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 200, borderRadius: 20),
          const SizedBox(height: 16),
          SkeletonLine(width: MediaQuery.of(context).size.width * 0.7),
          const SizedBox(height: 8),
          SkeletonLine(width: MediaQuery.of(context).size.width * 0.5, height: 14),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: SkeletonBox(height: 40, borderRadius: 20)),
              const SizedBox(width: 12),
              const Expanded(child: SkeletonBox(height: 40, borderRadius: 20)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for profile header
class SkeletonProfileHeader extends StatelessWidget {
  const SkeletonProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonCircle(size: 100),
        const SizedBox(height: 16),
        SkeletonLine(width: MediaQuery.of(context).size.width * 0.4, height: 24),
        const SizedBox(height: 8),
        SkeletonLine(width: MediaQuery.of(context).size.width * 0.3, height: 16),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Column(
              children: [
                SkeletonLine(width: 60, height: 28),
                SizedBox(height: 4),
                SkeletonLine(width: 60, height: 14),
              ],
            ),
            const Column(
              children: [
                SkeletonLine(width: 60, height: 28),
                SizedBox(height: 4),
                SkeletonLine(width: 60, height: 14),
              ],
            ),
            const Column(
              children: [
                SkeletonLine(width: 60, height: 28),
                SizedBox(height: 4),
                SkeletonLine(width: 60, height: 14),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
