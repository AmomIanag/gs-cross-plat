import '../core/formatters.dart';
import '../models/app_settings.dart';
import '../models/metric_point.dart';
import '../models/territory_alert.dart';
import '../models/weather_snapshot.dart';

class AlertEngine {
  const AlertEngine();

  List<TerritoryAlert> generate({
    required MetricSeries water,
    required MetricSeries energy,
    required AppSettings settings,
    WeatherSnapshot? weather,
  }) {
    final alerts = <TerritoryAlert>[
      _waterAlert(water, settings),
      _energyAlert(energy, settings),
      if (weather != null) _climateAlert(weather, settings),
    ];
    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return alerts;
  }

  TerritoryAlert _waterAlert(MetricSeries series, AppSettings settings) {
    final value = series.points.latestValue;
    final threshold = settings.waterThreshold;
    final severity = value >= threshold * 1.15
        ? AlertSeverity.critical
        : value >= threshold
        ? AlertSeverity.attention
        : AlertSeverity.normal;
    return TerritoryAlert(
      id: 'water-consumption',
      category: AlertCategory.water,
      severity: severity,
      title: severity == AlertSeverity.normal
          ? 'Consumo de água dentro do limiar'
          : 'Consumo de água acima do limiar',
      indicator: 'Consumo residencial médio sintético',
      evidence:
          '${formatNumber(value, decimals: 1)} L/hab/dia no período mais recente; limiar de ${formatNumber(threshold, decimals: 1)} L/hab/dia.',
      rule: 'Atenção quando valor ≥ limiar. Crítico quando valor ≥ 115% do limiar.',
      justification: severity == AlertSeverity.normal
          ? 'A observação mais recente permanece abaixo do limite configurado.'
          : 'A observação mais recente ultrapassou o limite configurado pelo usuário.',
      confidence: ConfidenceLevel.medium,
      confidenceRationale: 'Série completa e regra reproduzível, mas os valores são sintéticos. A classificação não é uma probabilidade estatística.',
      limitations: 'Dados sintéticos, agregados mensalmente e sem diferenças entre bairros, sazonalidade detalhada ou perdas da rede.',
      recommendation: 'Validar com medições oficiais e contexto operacional antes de planejar qualquer ação.',
      updatedAt: series.points.last.date,
    );
  }

  TerritoryAlert _energyAlert(MetricSeries series, AppSettings settings) {
    final points = series.points;
    final hasWindow = points.length >= 6;
    final previousAverage = hasWindow
        ? points.meanRange(points.length - 6, points.length - 3)
        : points.previousValue;
    final currentAverage = hasWindow
        ? points.meanRange(points.length - 3, points.length)
        : points.latestValue;
    final growth = previousAverage == 0
        ? 0.0
        : ((currentAverage - previousAverage) / previousAverage) * 100;
    final threshold = settings.energyGrowthThreshold;
    final severity = growth >= threshold + 10
        ? AlertSeverity.critical
        : growth >= threshold
        ? AlertSeverity.attention
        : AlertSeverity.normal;
    return TerritoryAlert(
      id: 'energy-growth',
      category: AlertCategory.energy,
      severity: severity,
      title: severity == AlertSeverity.normal
          ? 'Crescimento energético estável'
          : 'Crescimento energético relevante',
      indicator: 'Média móvel de consumo energético sintético',
      evidence:
          'Média dos 3 últimos períodos: ${formatNumber(currentAverage, decimals: 1)} MWh/dia; variação de ${formatSignedPercent(growth)} sobre os 3 anteriores.',
      rule:
          'Atenção quando crescimento ≥ ${formatNumber(threshold, decimals: 1)}%. Crítico quando ≥ ${formatNumber(threshold + 10, decimals: 1)}%.',
      justification: severity == AlertSeverity.normal
          ? 'O crescimento entre as janelas comparadas ficou abaixo do limiar.'
          : 'A média recente cresceu acima do limite configurado.',
      confidence: hasWindow ? ConfidenceLevel.medium : ConfidenceLevel.low,
      confidenceRationale: hasWindow
          ? 'As duas janelas têm três observações, mas os dados são sintéticos. A classificação não é uma probabilidade estatística.'
          : 'Há menos de seis observações para comparar janelas completas.',
      limitations: 'Série sintética agregada, sem controle de temperatura, população, tarifa ou atividade econômica.',
      recommendation: 'Comparar com dados oficiais, clima e eventos locais; investigar a causa sem presumir desperdício.',
      updatedAt: points.last.date,
    );
  }

  TerritoryAlert _climateAlert(WeatherSnapshot weather, AppSettings settings) {
    final probability = weather.maxPrecipitationProbability;
    final threshold = settings.rainProbabilityThreshold;
    final severity = probability >= (threshold + 20).clamp(0, 100)
        ? AlertSeverity.critical
        : probability >= threshold
        ? AlertSeverity.attention
        : AlertSeverity.normal;
    final complete = weather.points.length >= 24;
    final confidence = !complete
        ? ConfidenceLevel.low
        : weather.origin == WeatherDataOrigin.live
        ? ConfidenceLevel.high
        : ConfidenceLevel.medium;
    return TerritoryAlert(
      id: 'climate-rain',
      category: AlertCategory.climate,
      severity: severity,
      title: severity == AlertSeverity.normal
          ? 'Precipitação sem alerta configurado'
          : 'Possível precipitação relevante',
      indicator: 'Probabilidade máxima de precipitação nas próximas 24 horas',
      evidence:
          'Máximo previsto de ${formatNumber(probability)}%; limiar de ${formatNumber(threshold)}%.',
      rule: 'Atenção quando probabilidade ≥ limiar. Crítico quando ≥ limiar + 20 p.p. (máximo de 100%).',
      justification: severity == AlertSeverity.normal
          ? 'A previsão permaneceu abaixo do limite configurado.'
          : 'A previsão horária atingiu ou superou o limite configurado.',
      confidence: confidence,
      confidenceRationale: complete
          ? weather.origin == WeatherDataOrigin.live
                ? 'Previsão atual obtida da Open-Meteo e 24 pontos horários completos. A confiança é qualitativa, não uma probabilidade calibrada.'
                : 'Há 24 pontos completos, porém provenientes do cache. A confiança é qualitativa, não uma probabilidade calibrada.'
          : 'A janela disponível tem menos de 24 pontos horários.',
      limitations: 'Previsões podem mudar e não substituem alertas da Defesa Civil. O ponto geográfico central não representa todos os bairros.',
      recommendation: 'Acompanhar fontes oficiais e avaliar vulnerabilidades locais antes de decidir medidas preventivas.',
      updatedAt: weather.fetchedAt,
    );
  }
}
