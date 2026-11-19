import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/metric_point.dart';
import '../../models/weather_snapshot.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/metric_line_chart.dart';

class ClimateDashboardScreen extends ConsumerWidget {
  const ClimateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final threshold = ref.watch(settingsProvider).rainProbabilityThreshold;
    return PageContainer(
      refreshIndicator: () => ref.read(weatherProvider.notifier).refresh(),
      children: [
        const PageHeading(
          eyebrow: 'Dashboard territorial',
          title: 'Clima e riscos',
          subtitle: 'Previsão horária pública para apoiar leitura de temperatura e precipitação em São Paulo.',
        ),
        const SizedBox(height: 22),
        weather.when(
          loading: () => const LoadingCard(label: 'Consultando Open-Meteo…'),
          error: (error, _) => ErrorState(
            message:
                'Sem resposta da Open-Meteo e sem cache válido neste dispositivo. $error',
            onRetry: () => ref.read(weatherProvider.notifier).refresh(),
          ),
          data: (snapshot) =>
              _ClimateContent(snapshot: snapshot, threshold: threshold),
        ),
      ],
    );
  }
}

class _ClimateContent extends StatelessWidget {
  const _ClimateContent({required this.snapshot, required this.threshold});

  final WeatherSnapshot snapshot;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final temperaturePoints = snapshot.points
        .map((point) => MetricPoint(date: point.time, value: point.temperature))
        .toList();
    final probabilityPoints = snapshot.points
        .map(
          (point) => MetricPoint(
            date: point.time,
            value: point.precipitationProbability,
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBanner(
          icon: snapshot.origin == WeatherDataOrigin.live
              ? Icons.cloud_done_outlined
              : Icons.offline_bolt_outlined,
          title: snapshot.origin == WeatherDataOrigin.live
              ? 'Dados ao vivo da Open-Meteo'
              : 'Modo offline · cache local',
          message:
              '${snapshot.location} (${snapshot.latitude.toStringAsFixed(4)}, ${snapshot.longitude.toStringAsFixed(4)}) · atualização ${formatDateTime(snapshot.fetchedAt)}.',
          color: snapshot.origin == WeatherDataOrigin.live
              ? AppColors.normal
              : AppColors.attention,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 650
                ? (constraints.maxWidth - 20) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _ClimateStat(
                    label: 'Temperatura atual',
                    value:
                        '${formatNumber(snapshot.currentTemperature, decimals: 1)} °C',
                    icon: Icons.thermostat_rounded,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ClimateStat(
                    label: 'Precipitação atual',
                    value:
                        '${formatNumber(snapshot.currentPrecipitation, decimals: 1)} mm',
                    icon: Icons.water_drop_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ClimateStat(
                    label: 'Máx. probabilidade 24h',
                    value:
                        '${formatNumber(snapshot.maxPrecipitationProbability)}%',
                    icon: Icons.water_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const SectionHeading(
          'Temperatura nas próximas 24 horas',
          subtitle: 'Previsão horária em °C.',
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 22, 18, 12),
            child: MetricLineChart(
              points: temperaturePoints,
              color: AppColors.climate,
              xAxisMode: ChartXAxisMode.hourly,
              semanticLabel:
                  'Gráfico da previsão de temperatura para as próximas 24 horas. Máxima de ${formatNumber(snapshot.maxTemperature, decimals: 1)} graus Celsius.',
            ),
          ),
        ),
        const SizedBox(height: 26),
        const SectionHeading(
          'Probabilidade de precipitação',
          subtitle: 'Limiar configurado indicado pela linha tracejada.',
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 22, 18, 12),
            child: MetricLineChart(
              points: probabilityPoints,
              color: AppColors.water,
              threshold: threshold,
              thresholdLabel:
                  'Limiar · ${formatNumber(threshold, decimals: 0)}%',
              xAxisMode: ChartXAxisMode.hourly,
              fixedMinY: 0,
              fixedMaxY: 100,
              semanticLabel:
                  'Gráfico da probabilidade de precipitação. Máxima de ${formatNumber(snapshot.maxPrecipitationProbability)} por cento e limiar de ${formatNumber(threshold)} por cento.',
            ),
          ),
        ),
        const SizedBox(height: 22),
        const InfoBanner(
          icon: Icons.warning_amber_rounded,
          title: 'Leitura responsável',
          message: 'A previsão do ponto central não representa todos os bairros e pode mudar. Consulte Defesa Civil e fontes oficiais para decisões de segurança.',
          color: AppColors.attention,
        ),
      ],
    );
  }
}

class _ClimateStat extends StatelessWidget {
  const _ClimateStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.climate.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.climate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
