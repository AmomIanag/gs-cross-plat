import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/metric_point.dart';

class LocalMetricDataSource {
  const LocalMetricDataSource();

  Future<MetricSeries> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final metadata = json['metadata'] as Map<String, dynamic>;
    final points = (json['series'] as List<dynamic>)
        .map(
          (dynamic item) => MetricPoint.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    if (points.isEmpty) {
      throw const FormatException('A série histórica local está vazia.');
    }

    return MetricSeries(
      title: metadata['title'] as String,
      territory: metadata['territory'] as String,
      unit: metadata['unit'] as String,
      source: metadata['source'] as String,
      points: points,
    );
  }
}
