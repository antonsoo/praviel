import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// Premium chart widgets for 2025 UI standards
/// Beautiful, animated, interactive

class PremiumLineChart extends StatefulWidget {
  const PremiumLineChart({
    super.key,
    required this.data,
    required this.labels,
    this.title,
    this.height = 200,
    this.showDots = true,
    this.showGrid = true,
    this.gradient,
  });

  final List<double> data;
  final List<String> labels;
  final String? title;
  final double height;
  final bool showDots;
  final bool showGrid;
  final Gradient? gradient;

  @override
  State<PremiumLineChart> createState() => _PremiumLineChartState();
}

class _PremiumLineChartState extends State<PremiumLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.smooth,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedData = widget.data
            .map((value) => value * _animation.value)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VibrantSpacing.md),
            ],
            SizedBox(
              height: widget.height,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: widget.showGrid,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < widget.labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                widget.labels[index],
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: animatedData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      gradient: widget.gradient ?? VibrantTheme.auroraGradient,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: widget.showDots,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.3),
                            colorScheme.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PremiumBarChart extends StatefulWidget {
  const PremiumBarChart({
    super.key,
    required this.data,
    required this.labels,
    this.title,
    this.height = 200,
    this.showGrid = true,
  });

  final List<double> data;
  final List<String> labels;
  final String? title;
  final double height;
  final bool showGrid;

  @override
  State<PremiumBarChart> createState() => _PremiumBarChartState();
}

class _PremiumBarChartState extends State<PremiumBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.playful,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VibrantSpacing.md),
            ],
            SizedBox(
              height: widget.height,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: widget.data.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < widget.labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                widget.labels[index],
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: widget.showGrid,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: widget.data.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value * _animation.value,
                          gradient: VibrantTheme.auroraGradient,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PremiumPieChart extends StatefulWidget {
  const PremiumPieChart({
    super.key,
    required this.data,
    this.title,
    this.height = 200,
    this.showPercentage = true,
  });

  final List<PieData> data;
  final String? title;
  final double height;
  final bool showPercentage;

  @override
  State<PremiumPieChart> createState() => _PremiumPieChartState();
}

class _PremiumPieChartState extends State<PremiumPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.smooth,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VibrantSpacing.md),
            ],
            SizedBox(
              height: widget.height,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: widget.data.asMap().entries.map((entry) {
                    final isTouched = entry.key == _touchedIndex;
                    final radius = isTouched ? 110.0 : 100.0;
                    return PieChartSectionData(
                      color: entry.value.color,
                      value: entry.value.value * _animation.value,
                      title: widget.showPercentage
                          ? '${(entry.value.value).toInt()}%'
                          : entry.value.label,
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: VibrantSpacing.lg),
            Wrap(
              spacing: VibrantSpacing.md,
              runSpacing: VibrantSpacing.sm,
              children: widget.data.map((data) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.xs),
                    Text(
                      data.label,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class PieData {
  const PieData({
    required this.value,
    required this.label,
    required this.color,
  });

  final double value;
  final String label;
  final Color color;
}
