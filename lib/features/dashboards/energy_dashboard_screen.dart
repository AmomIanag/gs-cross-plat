import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/metric_point.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import 'consumption_dashboard.dart';

class EnergyDashboardScreen extends ConsumerWidget {
  const EnergyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(energySeriesProvider);
    final threshold = ref.watch(settingsProvider).energyGrowthThreshold;
    return series.when(
      loading: () => const PageContainer(children: [LoadingCard()]),
      error: (error, _) => PageContainer(
        children: [
          ErrorState(
            message: 'Falha ao ler a série local de energia: $error',
            onRetry: () => ref.invalidate(energySeriesProvider),
          ),
        ],
      ),
      data: (data) {
        final points = data.points;
        final previous = points.meanRange(points.length - 6, points.length - 3);
        final recent = points.meanRange(points.length - 3, points.length);
        final growth = ((recent - previous) / previous) * 100;
        final absoluteThreshold = previous * (1 + threshold / 100);
        return ConsumptionDashboard(
          series: data,
          eyebrow: 'Dashboard territorial',
          title: 'Consumo de energia',
          subtitle: 'Comparação entre janelas mensais para identificar aceleração de consumo e possíveis anomalias.',
          color: AppColors.energy,
          icon: Icons.bolt_outlined,
          threshold: absoluteThreshold,
          chartThresholdLabel:
              'Limiar 3m · ${formatNumber(absoluteThreshold, decimals: 1)}',
          comparisonLabel: 'Crescimento 3×3 meses',
          comparisonValue: formatSignedPercent(growth),
          comparisonElevated: growth >= threshold,
          explanation: 'A média dos três meses mais recentes é comparada à média dos três anteriores. Essa suavização reduz o efeito de um único mês, mas não corrige sazonalidade ou fatores externos.',
          ruleExplanation:
              'A linha tracejada representa ${formatNumber(absoluteThreshold, decimals: 1)} MWh/dia: média dos 3 períodos anteriores (${formatNumber(previous, decimals: 1)}) × (1 + ${formatNumber(threshold, decimals: 1)}%). O alerta compara a média recente (${formatNumber(recent, decimals: 1)}) com esse valor. Atenção ocorre no limiar; crítico, 10 pontos percentuais acima.',
        );
      },
    );
  }
}
