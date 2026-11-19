import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/metric_point.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/metric_line_chart.dart';

class ConsumptionDashboard extends StatelessWidget {
  const ConsumptionDashboard({
    required this.series,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.threshold,
    required this.comparisonLabel,
    required this.comparisonValue,
    required this.explanation,
    required this.ruleExplanation,
    this.chartThresholdLabel,
    this.comparisonElevated,
    super.key,
  });

  final MetricSeries series;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final double threshold;
  final String comparisonLabel;
  final String comparisonValue;
  final String explanation;
  final String ruleExplanation;
  final String? chartThresholdLabel;
  final bool? comparisonElevated;

  @override
  Widget build(BuildContext context) {
    final points = series.points;
    final latest = points.latestValue;
    final variation = points.latestVariationPercent;
    final elevated = comparisonElevated ?? latest >= threshold;
    return PageContainer(
      children: [
        PageHeading(eyebrow: eyebrow, title: title, subtitle: subtitle),
        const SizedBox(height: 22),
        InfoBanner(
          icon: Icons.science_outlined,
          title: 'Dados sintéticos identificados',
          message: series.source,
          color: color,
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
                  child: _StatCard(
                    label: 'Último período',
                    value:
                        '${formatNumber(latest, decimals: 1)} ${series.unit}',
                    icon: icon,
                    color: color,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _StatCard(
                    label: 'Variação mensal',
                    value: formatSignedPercent(variation),
                    icon: variation >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: variation > 0
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _StatCard(
                    label: comparisonLabel,
                    value: comparisonValue,
                    icon: elevated
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: elevated
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const SectionHeading(
          'Evolução temporal',
          subtitle: 'Média mensal · toque na linha para consultar valores.',
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 22, 18, 12),
            child: MetricLineChart(
              points: points,
              color: color,
              threshold: threshold,
              thresholdLabel: chartThresholdLabel,
              semanticLabel:
                  'Gráfico temporal de $title com ${points.length} observações. Valor mais recente ${formatNumber(latest, decimals: 1)} ${series.unit}.',
            ),
          ),
        ),
        const SizedBox(height: 26),
        const SectionHeading('Como interpretar'),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(explanation),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Regra utilizada',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(ruleExplanation),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.person_search_outlined,
          title: 'Análise humana necessária',
          message: 'Uma tendência não explica sua causa. Confirme com dados oficiais, sazonalidade e contexto local antes de agir.',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
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
