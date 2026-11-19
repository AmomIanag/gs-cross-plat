import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../core/formatters.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import 'consumption_dashboard.dart';

class WaterDashboardScreen extends ConsumerWidget {
  const WaterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(waterSeriesProvider);
    final threshold = ref.watch(settingsProvider).waterThreshold;
    return series.when(
      loading: () => const PageContainer(children: [LoadingCard()]),
      error: (error, _) => PageContainer(
        children: [
          ErrorState(
            message: 'Falha ao ler a série local de água: $error',
            onRetry: () => ref.invalidate(waterSeriesProvider),
          ),
        ],
      ),
      data: (data) => ConsumptionDashboard(
        series: data,
        eyebrow: 'Dashboard territorial',
        title: 'Consumo de água',
        subtitle: 'Histórico demonstrativo de consumo residencial médio para reconhecer elevações e apoiar investigação.',
        color: AppColors.water,
        icon: Icons.water_drop_outlined,
        threshold: threshold,
        chartThresholdLabel: 'Limiar · ${formatNumber(threshold, decimals: 1)}',
        comparisonLabel: 'Limiar configurado',
        comparisonValue: '${formatNumber(threshold, decimals: 1)} L/hab/dia',
        explanation: 'A série apresenta crescimento nos meses recentes. O último valor é comparado diretamente com o limiar do usuário; ultrapassá-lo indica consumo elevado apenas para esta demonstração.',
        ruleExplanation:
            'Atenção quando o último valor é igual ou superior a ${formatNumber(threshold, decimals: 1)} L/hab/dia; crítico a partir de 115% desse limite.',
      ),
    );
  }
}
