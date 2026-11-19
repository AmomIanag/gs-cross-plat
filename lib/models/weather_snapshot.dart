class WeatherPoint {
  const WeatherPoint({
    required this.time,
    required this.temperature,
    required this.precipitation,
    required this.precipitationProbability,
  });

  final DateTime time;
  final double temperature;
  final double precipitation;
  final double precipitationProbability;
}

enum WeatherDataOrigin { live, cache }

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
    required this.currentTemperature,
    required this.currentPrecipitation,
    required this.points,
    required this.origin,
  });

  final String location;
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;
  final double currentTemperature;
  final double currentPrecipitation;
  final List<WeatherPoint> points;
  final WeatherDataOrigin origin;

  double get maxPrecipitationProbability => points.isEmpty
      ? 0
      : points
            .map((point) => point.precipitationProbability)
            .reduce((a, b) => a > b ? a : b);

  double get maxTemperature => points.isEmpty
      ? currentTemperature
      : points
            .map((point) => point.temperature)
            .reduce((a, b) => a > b ? a : b);

  WeatherSnapshot copyWith({WeatherDataOrigin? origin}) => WeatherSnapshot(
    location: location,
    latitude: latitude,
    longitude: longitude,
    fetchedAt: fetchedAt,
    currentTemperature: currentTemperature,
    currentPrecipitation: currentPrecipitation,
    points: points,
    origin: origin ?? this.origin,
  );

  Map<String, dynamic> toJson() => {
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'fetchedAt': fetchedAt.toIso8601String(),
    'currentTemperature': currentTemperature,
    'currentPrecipitation': currentPrecipitation,
    'points': points
        .map(
          (point) => {
            'time': point.time.toIso8601String(),
            'temperature': point.temperature,
            'precipitation': point.precipitation,
            'precipitationProbability': point.precipitationProbability,
          },
        )
        .toList(),
  };

  factory WeatherSnapshot.fromJson(
    Map<String, dynamic> json, {
    WeatherDataOrigin origin = WeatherDataOrigin.live,
  }) {
    return WeatherSnapshot(
      location: json['location'] as String? ?? 'São Paulo/SP',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      currentTemperature: (json['currentTemperature'] as num).toDouble(),
      currentPrecipitation: (json['currentPrecipitation'] as num).toDouble(),
      points: (json['points'] as List<dynamic>).map((dynamic rawItem) {
        final item = rawItem as Map<String, dynamic>;
        return WeatherPoint(
          time: DateTime.parse(item['time'] as String),
          temperature: (item['temperature'] as num).toDouble(),
          precipitation: (item['precipitation'] as num).toDouble(),
          precipitationProbability: (item['precipitationProbability'] as num)
              .toDouble(),
        );
      }).toList(),
      origin: origin,
    );
  }
}
