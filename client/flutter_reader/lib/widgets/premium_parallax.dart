import 'package:flutter/material.dart';

/// Parallax scrolling effect widget
/// Creates depth by moving background slower than foreground
class ParallaxScrollEffect extends StatefulWidget {
  const ParallaxScrollEffect({
    super.key,
    required this.background,
    required this.foreground,
    this.parallaxFactor = 0.5,
  });

  final Widget background;
  final Widget foreground;
  final double parallaxFactor;

  @override
  State<ParallaxScrollEffect> createState() => _ParallaxScrollEffectState();
}

class _ParallaxScrollEffectState extends State<ParallaxScrollEffect> {
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _scrollOffset = notification.metrics.pixels;
          });
        }
        return false;
      },
      child: Stack(
        children: [
          // Background with parallax
          Transform.translate(
            offset: Offset(0, _scrollOffset * widget.parallaxFactor),
            child: widget.background,
          ),
          // Foreground
          widget.foreground,
        ],
      ),
    );
  }
}

/// Parallax image that responds to scroll position
class ParallaxImage extends StatelessWidget {
  const ParallaxImage({
    super.key,
    required this.imagePath,
    this.height = 300,
    this.parallaxStrength = 0.3,
  });

  final String imagePath;
  final double height;
  final double parallaxStrength;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Flow(
            delegate: _ParallaxFlowDelegate(
              scrollable: Scrollable.of(context),
              listItemContext: context,
              backgroundImageKey: GlobalKey(),
              parallaxStrength: parallaxStrength,
            ),
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: constraints.maxWidth,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.backgroundImageKey,
    required this.parallaxStrength,
  }) : super(repaint: scrollable?.position);

  final ScrollableState? scrollable;
  final BuildContext listItemContext;
  final GlobalKey backgroundImageKey;
  final double parallaxStrength;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // Calculate the position of this list item within the viewport
    final scrollableBox = scrollable?.context.findRenderObject() as RenderBox?;
    final listItemBox = listItemContext.findRenderObject() as RenderBox?;

    if (scrollableBox == null || listItemBox == null) {
      return;
    }

    final listItemOffset = listItemBox.localToGlobal(
      listItemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    final viewportDimension = scrollable?.position.viewportDimension ?? 0;
    final scrollFraction =
        (listItemOffset.dy / viewportDimension).clamp(0.0, 1.0);

    final verticalAlignment = Alignment(0, scrollFraction * 2 - 1);

    final backgroundSize =
        (backgroundImageKey.currentContext?.findRenderObject() as RenderBox?)
                ?.size ??
            Size.zero;

    final listItemSize = listItemBox.size;
    final childRect = verticalAlignment.inscribe(
      backgroundSize,
      Offset.zero & listItemSize,
    );

    context.paintChild(
      0,
      transform: Transform.translate(
        offset: Offset(0, childRect.top * parallaxStrength),
      ).transform,
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext ||
        backgroundImageKey != oldDelegate.backgroundImageKey ||
        parallaxStrength != oldDelegate.parallaxStrength;
  }
}

/// Simple parallax container for hero sections
class ParallaxHero extends StatefulWidget {
  const ParallaxHero({
    super.key,
    required this.child,
    this.backgroundGradient,
    this.height = 400,
    this.parallaxFactor = 0.4,
  });

  final Widget child;
  final Gradient? backgroundGradient;
  final double height;
  final double parallaxFactor;

  @override
  State<ParallaxHero> createState() => _ParallaxHeroState();
}

class _ParallaxHeroState extends State<ParallaxHero> {
  final ScrollController _scrollController = ScrollController();
  double _offset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _offset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Parallax background
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, _offset * widget.parallaxFactor),
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.backgroundGradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                      ),
                ),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Multi-layer parallax effect
/// Each layer moves at different speeds for depth
class MultiLayerParallax extends StatefulWidget {
  const MultiLayerParallax({
    super.key,
    required this.layers,
    this.scrollController,
  });

  final List<ParallaxLayer> layers;
  final ScrollController? scrollController;

  @override
  State<MultiLayerParallax> createState() => _MultiLayerParallaxState();
}

class _MultiLayerParallaxState extends State<MultiLayerParallax> {
  ScrollController? _internalController;
  double _offset = 0.0;

  ScrollController get _controller =>
      widget.scrollController ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _internalController = ScrollController();
    }
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _offset = _controller.offset;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.layers.map((layer) {
        return Transform.translate(
          offset: Offset(0, _offset * layer.parallaxFactor),
          child: layer.child,
        );
      }).toList(),
    );
  }
}

class ParallaxLayer {
  const ParallaxLayer({
    required this.child,
    required this.parallaxFactor,
  });

  final Widget child;
  final double parallaxFactor;
}
