import 'package:flutter/material.dart';

class BarData {
  final String label;
  final double value;
  final Color? color;
  BarData({required this.label, required this.value, this.color});
}

class SimpleBarChart extends StatelessWidget {
  final List<BarData> data;
  final double maxValue;
  final double barWidth;
  final double barRadius;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.maxValue = 0,
    this.barWidth = 28,
    this.barRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualMax = maxValue > 0
        ? maxValue
        : data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final effectiveMax = actualMax < 1 ? 1.0 : actualMax;
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.map((d) {
          final fraction = d.value / effectiveMax;
          final barHeight = (fraction * 120).clamp(4.0, 120.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: d.color ?? theme.colorScheme.primary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(barRadius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      (d.color ?? theme.colorScheme.primary).withValues(alpha: 0.7),
                      d.color ?? theme.colorScheme.primary,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
