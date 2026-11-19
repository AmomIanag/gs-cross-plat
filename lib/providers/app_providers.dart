import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_metric_data_source.dart';
import '../data/preferences_local_data_source.dart';
import '../data/weather_remote_data_source.dart';
import '../models/app_settings.dart';
import '../models/metric_point.dart';
import '../models/territory_alert.dart';
import '../models/weather_snapshot.dart';
import '../repositories/territory_repository.dart';
import '../repositories/weather_repository.dart';
import '../services/alert_engine.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences deve ser sobrescrito.'),
);

final preferencesDataSourceProvider = Provider(
  (ref) => PreferencesLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

final territoryRepositoryProvider = Provider(
  (ref) => const TerritoryRepository(LocalMetricDataSource()),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final weatherRepositoryProvider = Provider(
  (ref) => WeatherRepository(
    WeatherRemoteDataSource(ref.watch(httpClientProvider)),
    ref.watch(preferencesDataSourceProvider),
  ),
);

final waterSeriesProvider = FutureProvider<MetricSeries>(
  (ref) => ref.watch(territoryRepositoryProvider).loadWater(),
);

final energySeriesProvider = FutureProvider<MetricSeries>(
  (ref) => ref.watch(territoryRepositoryProvider).loadEnergy(),
);

class WeatherController extends AsyncNotifier<WeatherSnapshot> {
  @override
  Future<WeatherSnapshot> build() =>
      ref.watch(weatherRepositoryProvider).loadWeather();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(weatherRepositoryProvider).loadWeather(),
    );
  }
}

final weatherProvider =
    AsyncNotifierProvider<WeatherController, WeatherSnapshot>(
      WeatherController.new,
    );

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      ref.watch(preferencesDataSourceProvider).loadSettings();

  Future<void> save(AppSettings settings) async {
    await ref.read(preferencesDataSourceProvider).saveSettings(settings);
    state = settings;
  }

  Future<void> setThemeMode(ThemeMode themeMode) =>
      save(state.copyWith(themeMode: themeMode));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class ConsentController extends Notifier<ConsentState> {
  @override
  ConsentState build() =>
      ref.watch(preferencesDataSourceProvider).loadConsent();

  Future<void> complete({required bool optionalDiagnostics}) async {
    await ref
        .read(preferencesDataSourceProvider)
        .saveConsent(optionalDiagnostics: optionalDiagnostics);
    state = ConsentState(
      completed: true,
      optionalDiagnostics: optionalDiagnostics,
    );
  }
}

final consentProvider = NotifierProvider<ConsentController, ConsentState>(
  ConsentController.new,
);

final alertsProvider = FutureProvider<List<TerritoryAlert>>((ref) async {
  final settings = ref.watch(settingsProvider);
  final water = await ref.watch(waterSeriesProvider.future);
  final energy = await ref.watch(energySeriesProvider.future);
  WeatherSnapshot? weather;
  try {
    weather = await ref.watch(weatherProvider.future);
  } catch (_) {
    weather = null;
  }
  return AlertEngine().generate(
    water: water,
    energy: energy,
    settings: settings,
    weather: weather,
  );
});
