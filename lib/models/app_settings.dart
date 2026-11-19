import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.waterThreshold = 180,
    this.energyGrowthThreshold = 10,
    this.rainProbabilityThreshold = 70,
    this.themeMode = ThemeMode.system,
  });

  final double waterThreshold;
  final double energyGrowthThreshold;
  final double rainProbabilityThreshold;
  final ThemeMode themeMode;

  AppSettings copyWith({
    double? waterThreshold,
    double? energyGrowthThreshold,
    double? rainProbabilityThreshold,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      waterThreshold: waterThreshold ?? this.waterThreshold,
      energyGrowthThreshold:
          energyGrowthThreshold ?? this.energyGrowthThreshold,
      rainProbabilityThreshold:
          rainProbabilityThreshold ?? this.rainProbabilityThreshold,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ConsentState {
  const ConsentState({
    required this.completed,
    required this.optionalDiagnostics,
  });

  final bool completed;
  final bool optionalDiagnostics;
}
