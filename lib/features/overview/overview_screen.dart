import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/metric_point.dart';
import '../../models/territory_alert.dart';
import '../../models/weather_snapshot.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water = ref.watch(waterSeriesProvider);
    final energy = ref.watch(energySeriesProvider);
    final weather = ref.watch(weatherProvider);
    final alerts = ref.watch(alertsProvider);
    final domainsAvailable = [
      water.hasValue,
      energy.hasValue,
      weather.hasValue,
    ].where((available) => available).length;

    return PageContainer(
      refreshIndicator: () async {
        ref.invalidate(waterSeriesProvider);
        ref.invalidate(energySeriesProvider);
        await ref.read(weatherProvider.notifier).refresh();
        ref.invalidate(alertsProvider);
      },
      children: [
        const PageHeading(
          eyebrow: 'Visão geral · São Paulo/SP',
          title: 'O território em perspectiva',
          subtitle: 'Indicadores integrados para reconhecer tendências, priorizar investigações e apoiar decisões responsáveis.',
        ),
        const SizedBox(height: 24),
        _TerritoryHero(alerts: alerts),
        const SizedBox(height: 28),
        const SectionHeading(
          'Indicadores monitorados',
          subtitle: 'Toque em um card para explorar histórico e metodologia.',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            final width = wide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _IndicatorCard(
                    title: 'Água',
                    icon: Icons.water_drop_outlined,
                    color: AppColors.water,
                    value: water.when(
                      data: (series) =>
                          '${formatNumber(series.points.latestValue, decimals: 1)} L/hab/dia',
                      error: (error, stackTrace) => 'Indisponível',
                      loading: () => 'Carregando…',
                    ),
                    caption: 'Série mensal sintética',
                    onTap: () => context.push('/water'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _IndicatorCard(
                    title: 'Energia',
                    icon: Icons.bolt_outlined,
                    color: AppColors.energy,
                    value: energy.when(
                      data: (series) =>
                          '${formatNumber(series.points.latestValue, decimals: 1)} MWh/dia',
                      error: (error, stackTrace) => 'Indisponível',
                      loading: () => 'Carregando…',
                    ),
                    caption: 'Por 10 mil domicílios · sintético',
                    onTap: () => context.push('/energy'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _IndicatorCard(
                    title: 'Clima',
                    icon: Icons.cloud_outlined,
                    color: AppColors.climate,
                    value: weather.when(
                      data: (snapshot) =>
                          '${formatNumber(snapshot.currentTemperature, decimals: 1)} °C',
                      error: (error, stackTrace) => 'Indisponível',
                      loading: () => 'Atualizando…',
                    ),
                    caption: weather.value?.origin == WeatherDataOrigin.cache
                        ? 'Open-Meteo · cache local'
                        : 'Open-Meteo · previsão pública',
                    onTap: () => context.push('/climate'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const SectionHeading(
          'Benefício social potencial',
          subtitle: 'Indicador metodológico — não mede impacto real alcançado.',
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.normal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    color: AppColors.normal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$domainsAvailable de 3 domínios com dados disponíveis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Metodologia: conta água, energia e clima quando cada fonte possui ao menos uma observação utilizável. Indica cobertura informacional para análise humana; não afirma economia, pessoas beneficiadas ou melhoria causal.',
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: domainsAvailable / 3,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(99),
                        color: AppColors.normal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        SectionHeading(
          'Sinais recentes',
          trailing: TextButton(
            onPressed: () => context.go('/alerts'),
            child: const Text('Ver central'),
          ),
        ),
        const SizedBox(height: 14),
        alerts.when(
          loading: () => const LoadingCard(label: 'Calculando alertas…'),
          error: (error, _) => ErrorState(
            message: 'Não foi possível calcular os alertas: $error',
            onRetry: () => ref.invalidate(alertsProvider),
          ),
          data: (items) => Column(
            children: [
              for (final alert in items.take(3)) ...[
                _AlertPreview(alert: alert),
                if (alert != items.take(3).last) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const InfoBanner(
          icon: Icons.balance_outlined,
          title: 'Decisão humana no centro',
          message: 'Os sinais ajudam a direcionar análise. Nenhuma decisão de alto impacto é executada automaticamente pelo aplicativo.',
        ),
      ],
    );
  }
}

class _TerritoryHero extends StatelessWidget {
  const _TerritoryHero({required this.alerts});

  final AsyncValue<List<TerritoryAlert>> alerts;

  @override
  Widget build(BuildContext context) {
    final active =
        alerts.value
            ?.where((alert) => alert.severity != AlertSeverity.normal)
            .length ??
        0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E53), Color(0xFF0C7479)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MUNICÍPIO MONITORADO',
                  style: TextStyle(
                    color: Color(0xFFB9E9E3),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'São Paulo · SP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$active ${active == 1 ? 'sinal ativo' : 'sinais ativos'} para revisão',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String value;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Abrir dashboard de $title. Valor $value.',
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(caption, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AlertPreview extends StatelessWidget {
  const _AlertPreview({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/alerts/${alert.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: severityColor(alert.severity),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text('${alert.category.label} · ${alert.evidence}'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(severity: alert.severity),
          ],
        ),
      ),
    ),
  );
}
