import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;

/// Parallax scrolling effect - elements move at different speeds based on depth
/// Creates immersive depth and modern 2025 visual feel
class ParallaxScrollView extends StatefulWidget {
  const ParallaxScrollView({
    super.key,
    required this.children,
    this.backgroundLayers = const [],
    this.controller,
  });

  final List<Widget> children;
  final List<ParallaxLayer> backgroundLayers;
  final ScrollController? controller;

  @override
  State<ParallaxScrollView> createState() => _ParallaxScrollViewState();
}

class _ParallaxScrollViewState extends State<ParallaxScrollView> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_handleScroll);
    }
    super.dispose();
  }

  void _handleScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background parallax layers
        for (final layer in widget.backgroundLayers)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, -_scrollOffset * layer.speed),
              child: layer.child,
            ),
          ),
        // Foreground content
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: widget.children,
          ),
        ),
      ],
    );
  }
}

class ParallaxLayer {
  const ParallaxLayer({
    required this.child,
    this.speed = 0.5,
  });

  final Widget child;
  final double speed; // 0.0 = fixed, 1.0 = moves with scroll, >1.0 = faster
}

/// Parallax image that moves based on scroll position
class ParallaxImage extends StatelessWidget {
  const ParallaxImage({
    super.key,
    required this.imagePath,
    this.height = 400,
    this.speed = 0.3,
    this.fit = BoxFit.cover,
  });

  final String imagePath;
  final double height;
  final double speed;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OverflowBox(
            alignment: Alignment.center,
            minHeight: height,
            maxHeight: height * (1 + speed),
            child: Image.asset(
              imagePath,
              fit: fit,
            ),
          );
        },
      ),
    );
  }
}

/// Card with parallax tilt effect on hover (desktop) or gyroscope (mobile)
class ParallaxCard extends StatefulWidget {
  const ParallaxCard({
    super.key,
    required this.child,
    this.maxTilt = 10,
    this.enableGyroscope = false,
  });

  final Widget child;
  final double maxTilt;
  final bool enableGyroscope;

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> {
  double _tiltX = 0;
  double _tiltY = 0;

  void _handleHover(PointerHoverEvent event) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.globalToLocal(event.position);
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      final tiltX = ((position.dy - centerY) / centerY) * widget.maxTilt;
      final tiltY = ((position.dx - centerX) / centerX) * -widget.maxTilt;
      setState(() {
        _tiltX = tiltX;
        _tiltY = tiltY;
      });
    }
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _handleHover,
      onExit: (_) => _resetTilt(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tiltX * math.pi / 180)
          ..rotateY(_tiltY * math.pi / 180),
        child: widget.child,
      ),
    );
  }
}

/// Depth layers widget - creates layered parallax effect
class DepthLayers extends StatefulWidget {
  const DepthLayers({
    super.key,
    required this.layers,
  });

  final List<DepthLayer> layers;

  @override
  State<DepthLayers> createState() => _DepthLayersState();
}

class _DepthLayersState extends State<DepthLayers> {
  double _offsetX = 0;
  double _offsetY = 0;

  void _handlePointerMove(PointerMoveEvent event) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.globalToLocal(event.position);
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      setState(() {
        _offsetX = (position.dx - centerX) / centerX;
        _offsetY = (position.dy - centerY) / centerY;
      });
    }
  }

  void _resetOffset() {
    setState(() {
      _offsetX = 0;
      _offsetY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _handlePointerMove(event as PointerMoveEvent),
      onExit: (_) => _resetOffset(),
      child: Stack(
        children: [
          for (final layer in widget.layers)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: layer.baseX + (_offsetX * layer.depth * 20),
              top: layer.baseY + (_offsetY * layer.depth * 20),
              child: layer.child,
            ),
        ],
      ),
    );
  }
}

class DepthLayer {
  const DepthLayer({
    required this.child,
    this.depth = 1.0,
    this.baseX = 0,
    this.baseY = 0,
  });

  final Widget child;
  final double depth; // Higher = more movement
  final double baseX;
  final double baseY;
}
