import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:territorio_vivo/data/preferences_local_data_source.dart';
import 'package:territorio_vivo/models/app_settings.dart';
import 'package:territorio_vivo/models/weather_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('salva e recupera configurações e consentimento', () async {
    final preferences = await SharedPreferences.getInstance();
    final dataSource = PreferencesLocalDataSource(preferences);
    const settings = AppSettings(
      waterThreshold: 210,
      energyGrowthThreshold: 8,
      rainProbabilityThreshold: 65,
      themeMode: ThemeMode.dark,
    );

    await dataSource.saveSettings(settings);
    await dataSource.saveConsent(optionalDiagnostics: true);
    final loaded = dataSource.loadSettings();
    final consent = dataSource.loadConsent();

    expect(loaded.waterThreshold, 210);
    expect(loaded.energyGrowthThreshold, 8);
    expect(loaded.rainProbabilityThreshold, 65);
    expect(loaded.themeMode, ThemeMode.dark);
    expect(consent.completed, isTrue);
    expect(consent.optionalDiagnostics, isTrue);
  });

  test(
    'cache meteorológico preserva dados e marca origem como cache',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final dataSource = PreferencesLocalDataSource(preferences);
      final snapshot = WeatherSnapshot(
        location: 'São Paulo/SP',
        latitude: -23.55,
        longitude: -46.63,
        fetchedAt: DateTime(2026, 11, 19, 10),
        currentTemperature: 25,
        currentPrecipitation: 1.2,
        points: [
          WeatherPoint(
            time: DateTime(2026, 11, 19, 11),
            temperature: 26,
            precipitation: 0.4,
            precipitationProbability: 60,
          ),
        ],
        origin: WeatherDataOrigin.live,
      );

      await dataSource.saveWeather(snapshot);
      final cached = dataSource.loadWeather();

      expect(cached, isNotNull);
      expect(cached!.origin, WeatherDataOrigin.cache);
      expect(cached.currentTemperature, 25);
      expect(cached.points.single.precipitationProbability, 60);
    },
  );
}
