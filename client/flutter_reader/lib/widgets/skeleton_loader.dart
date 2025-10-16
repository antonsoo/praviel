import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';

/// Modern skeleton loading states with shimmer effect
/// Provides beautiful loading placeholders for all content types

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
              colors: isDark
                  ? [
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainerHigh,
                      colorScheme.surfaceContainer,
                    ]
                  : [
                      colorScheme.surfaceContainerLow,
                      colorScheme.surface,
                      colorScheme.surfaceContainerLow,
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card - for lesson cards, achievement cards, etc.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120, this.showImage = true});

  final double height;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        boxShadow: VibrantShadow.sm(Theme.of(context).colorScheme),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            SkeletonLoader(
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(VibrantRadius.md),
            ),
            const SizedBox(width: VibrantSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SkeletonLoader(width: double.infinity, height: 18),
                    const SizedBox(height: VibrantSpacing.xs),
                    const SkeletonLoader(width: 150, height: 14),
                    const SizedBox(height: VibrantSpacing.xs),
                    const SkeletonLoader(width: 100, height: 12),
                  ],
                ),
                Row(
                  children: [
                    const SkeletonLoader(width: 60, height: 12),
                    const Spacer(),
                    SkeletonLoader(
                      width: 80,
                      height: 28,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton list - shows multiple skeleton items
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 120,
    this.showImage = true,
    this.spacing = VibrantSpacing.md,
  });

  final int itemCount;
  final double itemHeight;
  final bool showImage;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (context, _) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        return SkeletonCard(height: itemHeight, showImage: showImage);
      },
    );
  }
}

/// Skeleton text - for text placeholders
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.lines = 3,
    this.spacing = VibrantSpacing.xs,
  });

  final int lines;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: SkeletonLoader(
            width: isLast ? 200 : double.infinity,
            height: 16,
          ),
        );
      }),
    );
  }
}

/// Skeleton avatar - for profile pictures
class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

/// Skeleton grid - for grid layouts
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.aspectRatio = 1.0,
  });

  final int crossAxisCount;
  final int itemCount;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: VibrantSpacing.md,
        mainAxisSpacing: VibrantSpacing.md,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            boxShadow: VibrantShadow.sm(Theme.of(context).colorScheme),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: Column(
                  children: const [
                    SkeletonLoader(width: double.infinity, height: 16),
                    SizedBox(height: VibrantSpacing.xs),
                    SkeletonLoader(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
