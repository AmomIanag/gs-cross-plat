import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/weather_snapshot.dart';

class PreferencesLocalDataSource {
  const PreferencesLocalDataSource(this._preferences);

  final SharedPreferences _preferences;

  static const _waterKey = 'water_threshold';
  static const _energyKey = 'energy_growth_threshold';
  static const _rainKey = 'rain_probability_threshold';
  static const _themeKey = 'theme_mode';
  static const _consentCompletedKey = 'consent_completed';
  static const _diagnosticsKey = 'optional_diagnostics';
  static const _weatherCacheKey = 'weather_cache_v1';

  AppSettings loadSettings() {
    final themeName = _preferences.getString(_themeKey);
    return AppSettings(
      waterThreshold: _preferences.getDouble(_waterKey) ?? 180,
      energyGrowthThreshold: _preferences.getDouble(_energyKey) ?? 10,
      rainProbabilityThreshold: _preferences.getDouble(_rainKey) ?? 70,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await Future.wait([
      _preferences.setDouble(_waterKey, settings.waterThreshold),
      _preferences.setDouble(_energyKey, settings.energyGrowthThreshold),
      _preferences.setDouble(_rainKey, settings.rainProbabilityThreshold),
      _preferences.setString(_themeKey, settings.themeMode.name),
    ]);
  }

  ConsentState loadConsent() => ConsentState(
    completed: _preferences.getBool(_consentCompletedKey) ?? false,
    optionalDiagnostics: _preferences.getBool(_diagnosticsKey) ?? false,
  );

  Future<void> saveConsent({required bool optionalDiagnostics}) async {
    await Future.wait([
      _preferences.setBool(_consentCompletedKey, true),
      _preferences.setBool(_diagnosticsKey, optionalDiagnostics),
    ]);
  }

  Future<void> saveWeather(WeatherSnapshot snapshot) =>
      _preferences.setString(_weatherCacheKey, jsonEncode(snapshot.toJson()));

  WeatherSnapshot? loadWeather() {
    final raw = _preferences.getString(_weatherCacheKey);
    if (raw == null) return null;
    try {
      return WeatherSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        origin: WeatherDataOrigin.cache,
      );
    } catch (_) {
      return null;
    }
  }
}
