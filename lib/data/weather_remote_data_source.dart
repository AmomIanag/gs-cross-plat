import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_snapshot.dart';

class WeatherException implements Exception {
  const WeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeatherRemoteDataSource {
  const WeatherRemoteDataSource(this._client);

  final http.Client _client;

  static const _latitude = -23.5505;
  static const _longitude = -46.6333;

  Future<WeatherSnapshot> fetch() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$_latitude',
      'longitude': '$_longitude',
      'current': 'temperature_2m,precipitation,rain,weather_code',
      'hourly': 'temperature_2m,precipitation,precipitation_probability',
      'timezone': 'America/Sao_Paulo',
      'forecast_days': '3',
    });

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw WeatherException(
          'A Open-Meteo respondeu com status ${response.statusCode}.',
        );
      }
      return _parse(jsonDecode(response.body) as Map<String, dynamic>);
    } on WeatherException {
      rethrow;
    } on FormatException {
      throw const WeatherException('A resposta meteorológica é inválida.');
    } catch (error) {
      throw WeatherException('Não foi possível consultar a Open-Meteo: $error');
    }
  }

  WeatherSnapshot _parse(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>?;
    final hourly = json['hourly'] as Map<String, dynamic>?;
    if (current == null || hourly == null) {
      throw const FormatException('Campos meteorológicos ausentes.');
    }

    final times = hourly['time'] as List<dynamic>;
    final temperatures = hourly['temperature_2m'] as List<dynamic>;
    final precipitations = hourly['precipitation'] as List<dynamic>;
    final probabilities = hourly['precipitation_probability'] as List<dynamic>;
    final shortest = [
      times.length,
      temperatures.length,
      precipitations.length,
      probabilities.length,
    ].reduce((a, b) => a < b ? a : b);
    if (shortest == 0) throw const FormatException('Previsão horária vazia.');

    final allPoints = List.generate(
      shortest,
      (index) => WeatherPoint(
        time: DateTime.parse(times[index] as String),
        temperature: (temperatures[index] as num).toDouble(),
        precipitation: (precipitations[index] as num).toDouble(),
        precipitationProbability: (probabilities[index] as num).toDouble(),
      ),
    );
    final currentTime = DateTime.tryParse(current['time'] as String? ?? '');
    final upcoming = allPoints
        .where(
          (point) =>
              currentTime == null ||
              !point.time.isBefore(
                currentTime.subtract(const Duration(hours: 1)),
              ),
        )
        .take(24)
        .toList();

    return WeatherSnapshot(
      location: 'São Paulo/SP',
      latitude: (json['latitude'] as num?)?.toDouble() ?? _latitude,
      longitude: (json['longitude'] as num?)?.toDouble() ?? _longitude,
      fetchedAt: DateTime.now(),
      currentTemperature: (current['temperature_2m'] as num).toDouble(),
      currentPrecipitation: (current['precipitation'] as num).toDouble(),
      points: upcoming.isEmpty ? allPoints.take(24).toList() : upcoming,
      origin: WeatherDataOrigin.live,
    );
  }
}
