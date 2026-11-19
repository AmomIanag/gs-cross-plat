class MetricPoint {
  const MetricPoint({required this.date, required this.value});

  final DateTime date;
  final double value;

  factory MetricPoint.fromJson(Map<String, dynamic> json) {
    return MetricPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class MetricSeries {
  const MetricSeries({
    required this.title,
    required this.territory,
    required this.unit,
    required this.source,
    required this.points,
  });

  final String title;
  final String territory;
  final String unit;
  final String source;
  final List<MetricPoint> points;
}

extension MetricPointListX on List<MetricPoint> {
  double get latestValue => isEmpty ? 0 : last.value;

  double get previousValue => length < 2 ? latestValue : this[length - 2].value;

  double get latestVariationPercent {
    if (length < 2 || previousValue == 0) return 0;
    return ((latestValue - previousValue) / previousValue) * 100;
  }

  double meanRange(int start, int end) {
    final range = sublist(start, end);
    if (range.isEmpty) return 0;
    return range.fold<double>(0, (sum, item) => sum + item.value) /
        range.length;
  }
}
