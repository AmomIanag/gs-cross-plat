import 'package:flutter_test/flutter_test.dart';
import 'package:territorio_vivo/models/app_settings.dart';
import 'package:territorio_vivo/models/metric_point.dart';
import 'package:territorio_vivo/models/territory_alert.dart';
import 'package:territorio_vivo/models/weather_snapshot.dart';
import 'package:territorio_vivo/services/alert_engine.dart';

void main() {
  const engine = AlertEngine();

  MetricSeries series(List<double> values, String unit) => MetricSeries(
    title: 'Teste',
    territory: 'São Paulo/SP',
    unit: unit,
    source: 'Sintético',
    points: [
      for (var index = 0; index < values.length; index++)
        MetricPoint(date: DateTime(2026, index + 1), value: values[index]),
    ],
  );

  test('água acima do limiar gera atenção com evidência numérica', () {
    final alerts = engine.generate(
      water: series([170, 181], 'L/hab/dia'),
      energy: series([10, 10, 10, 10, 10, 10], 'MWh'),
      settings: const AppSettings(waterThreshold: 180),
    );
    final alert = alerts.firstWhere(
      (item) => item.category == AlertCategory.water,
    );

    expect(alert.severity, AlertSeverity.attention);
    expect(alert.evidence, contains('181'));
    expect(alert.rule, contains('115%'));
  });

  test('água a 115% do limiar é classificada como crítica', () {
    final alerts = engine.generate(
      water: series([180, 207], 'L/hab/dia'),
      energy: series([10, 10, 10, 10, 10, 10], 'MWh'),
      settings: const AppSettings(waterThreshold: 180),
    );

    expect(
      alerts
          .firstWhere((item) => item.category == AlertCategory.water)
          .severity,
      AlertSeverity.critical,
    );
  });

  test('crescimento energético compara duas janelas de três períodos', () {
    final alerts = engine.generate(
      water: series([100, 100], 'L/hab/dia'),
      energy: series([10, 10, 10, 15, 15, 15], 'MWh'),
      settings: const AppSettings(energyGrowthThreshold: 10),
    );
    final alert = alerts.firstWhere(
      (item) => item.category == AlertCategory.energy,
    );

    expect(alert.severity, AlertSeverity.critical);
    expect(alert.evidence, contains('+50,0%'));
  });

  test('clima em cache reduz confiança qualitativa para média', () {
    final weather = WeatherSnapshot(
      location: 'São Paulo/SP',
      latitude: -23.55,
      longitude: -46.63,
      fetchedAt: DateTime(2026, 11, 19),
      currentTemperature: 24,
      currentPrecipitation: 0,
      points: [
        for (var hour = 0; hour < 24; hour++)
          WeatherPoint(
            time: DateTime(2026, 11, 19, hour),
            temperature: 24,
            precipitation: 0,
            precipitationProbability: hour == 12 ? 75 : 20,
          ),
      ],
      origin: WeatherDataOrigin.cache,
    );
    final alerts = engine.generate(
      water: series([100, 100], 'L/hab/dia'),
      energy: series([10, 10, 10, 10, 10, 10], 'MWh'),
      settings: const AppSettings(rainProbabilityThreshold: 70),
      weather: weather,
    );
    final alert = alerts.firstWhere(
      (item) => item.category == AlertCategory.climate,
    );

    expect(alert.severity, AlertSeverity.attention);
    expect(alert.confidence, ConfidenceLevel.medium);
    expect(alert.confidenceRationale, contains('cache'));
  });
}
