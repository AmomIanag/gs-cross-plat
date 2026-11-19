import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/metric_point.dart';

enum ChartXAxisMode { monthly, hourly }

class MetricLineChart extends StatelessWidget {
  const MetricLineChart({
    required this.points,
    required this.color,
    required this.semanticLabel,
    this.threshold,
    this.thresholdLabel,
    this.xAxisMode = ChartXAxisMode.monthly,
    this.fixedMinY,
    this.fixedMaxY,
    super.key,
  });

  final List<MetricPoint> points;
  final Color color;
  final String semanticLabel;
  final double? threshold;
  final String? thresholdLabel;
  final ChartXAxisMode xAxisMode;
  final double? fixedMinY;
  final double? fixedMaxY;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => point.value).toList();
    if (threshold != null) values.add(threshold!);
    final observedMin = values.reduce(math.min);
    final observedMax = values.reduce(math.max);
    final scale = _ChartYScale.calculate(
      minimum: fixedMinY ?? observedMin,
      maximum: fixedMaxY ?? observedMax,
      fixedMinimum: fixedMinY != null,
      fixedMaximum: fixedMaxY != null,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final chartHeight = (240 + ((textScale - 1).clamp(0, 1) * 36)).toDouble();

    return Semantics(
      label: semanticLabel,
      image: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final xLabelStep = _xLabelStep(
            availableWidth: constraints.maxWidth,
            textScale: textScale,
          );
          return SizedBox(
            height: chartHeight,
            child: LineChart(
              LineChartData(
                minY: scale.minimum,
                maxY: scale.maximum,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: scale.interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: scale.interval,
                      reservedSize: (42 * textScale).clamp(42, 62),
                      getTitlesWidget: (value, meta) => Text(
                        formatNumber(
                          value,
                          decimals: scale.interval % 1 == 0 ? 0 : 1,
                        ),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: xAxisMode == ChartXAxisMode.hourly
                          ? (44 * textScale).clamp(44, 64)
                          : (36 * textScale).clamp(36, 52),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 ||
                            index >= points.length ||
                            index % xLabelStep != 0) {
                          return const SizedBox.shrink();
                        }
                        final label = _xAxisLabel(index, xLabelStep);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: threshold == null
                    ? const ExtraLinesData()
                    : ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: threshold!,
                            color: Theme.of(context).colorScheme.error,
                            dashArray: [6, 5],
                            strokeWidth: 1.5,
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              labelResolver: (_) => thresholdLabel ?? 'Limiar',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            '${_tooltipDate(points[spot.x.round()].date)}\n${formatNumber(spot.y, decimals: 1)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var index = 0; index < points.length; index++)
                        FlSpot(index.toDouble(), points[index].value),
                    ],
                    color: color,
                    barWidth: 3,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, data) =>
                          spot.x == 0 || spot.x == points.length - 1,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.25),
                          color.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 450),
            ),
          );
        },
      ),
    );
  }

  int _xLabelStep({required double availableWidth, required double textScale}) {
    if (xAxisMode == ChartXAxisMode.monthly) {
      return points.length > 7 ? 3 : 1;
    }
    final minimumLabelWidth = textScale > 1.3 ? 76.0 : 58.0;
    final capacity = ((availableWidth - 54) / minimumLabelWidth).floor().clamp(
      2,
      7,
    );
    final desiredStep = (points.length / capacity).ceil();
    return desiredStep <= 4 ? 4 : 6;
  }

  String _xAxisLabel(int index, int step) {
    final date = points[index].date;
    if (xAxisMode == ChartXAxisMode.monthly) return formatMonth(date);
    final previousLabelIndex = index - step;
    final changedDay =
        previousLabelIndex < 0 ||
        points[previousLabelIndex].date.day != date.day ||
        points[previousLabelIndex].date.month != date.month ||
        points[previousLabelIndex].date.year != date.year;
    return changedDay ? formatHourWithDate(date) : formatHour(date);
  }

  String _tooltipDate(DateTime date) => xAxisMode == ChartXAxisMode.hourly
      ? formatChartDateTime(date)
      : formatMonth(date);
}

class _ChartYScale {
  const _ChartYScale({
    required this.minimum,
    required this.maximum,
    required this.interval,
  });

  final double minimum;
  final double maximum;
  final double interval;

  static _ChartYScale calculate({
    required double minimum,
    required double maximum,
    required bool fixedMinimum,
    required bool fixedMaximum,
  }) {
    var range = (maximum - minimum).abs();
    if (range == 0) range = math.max(maximum.abs() * 0.2, 1);
    final interval = _niceNumber(range / 4);
    final roundedMinimum = fixedMinimum
        ? minimum
        : (minimum / interval).floorToDouble() * interval;
    var roundedMaximum = fixedMaximum
        ? maximum
        : (maximum / interval).ceilToDouble() * interval;
    if (roundedMaximum <= roundedMinimum) {
      roundedMaximum = roundedMinimum + interval * 4;
    }
    return _ChartYScale(
      minimum: roundedMinimum,
      maximum: roundedMaximum,
      interval: interval,
    );
  }

  static double _niceNumber(double value) {
    if (value <= 0 || !value.isFinite) return 1;
    final exponent = math.pow(10, (math.log(value) / math.ln10).floor());
    final fraction = value / exponent;
    final niceFraction = fraction <= 1
        ? 1
        : fraction <= 2
        ? 2
        : fraction <= 2.5
        ? 2.5
        : fraction <= 5
        ? 5
        : 10;
    return (niceFraction * exponent).toDouble();
  }
}
