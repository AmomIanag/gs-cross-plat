import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../models/territory_alert.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({required this.alertId, super.key});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    return PageContainer(
      children: [
        alerts.when(
          loading: () => const LoadingCard(label: 'Carregando evidências…'),
          error: (error, _) => ErrorState(
            message: 'Falha ao recuperar o alerta: $error',
            onRetry: () => ref.invalidate(alertsProvider),
          ),
          data: (items) {
            TerritoryAlert? selected;
            for (final alert in items) {
              if (alert.id == alertId) selected = alert;
            }
            if (selected == null) return const _MissingAlert();
            return _AlertDetails(alert: selected);
          },
        ),
      ],
    );
  }
}

class _AlertDetails extends StatelessWidget {
  const _AlertDetails({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PageHeading(
        eyebrow: '${alert.category.label} · detalhe do sinal',
        title: alert.title,
        subtitle: 'Referência dos dados: ${formatDateTime(alert.updatedAt)}',
        trailing: StatusPill(severity: alert.severity),
      ),
      const SizedBox(height: 22),
      _EvidenceCard(alert: alert),
      const SizedBox(height: 16),
      _DetailSection(
        icon: Icons.straighten_rounded,
        title: 'Regra utilizada',
        body: alert.rule,
      ),
      const SizedBox(height: 12),
      _DetailSection(
        icon: Icons.fact_check_outlined,
        title: 'Justificativa baseada em evidências',
        body: alert.justification,
      ),
      const SizedBox(height: 12),
      _DetailSection(
        icon: Icons.verified_outlined,
        title: 'Confiança qualitativa: ${alert.confidence.label}',
        body: alert.confidenceRationale,
      ),
      const SizedBox(height: 12),
      _DetailSection(
        icon: Icons.report_problem_outlined,
        title: 'Limitações e possíveis vieses',
        body: alert.limitations,
      ),
      const SizedBox(height: 12),
      _DetailSection(
        icon: Icons.person_search_outlined,
        title: 'Recomendação não vinculante',
        body: alert.recommendation,
      ),
      const SizedBox(height: 18),
      InfoBanner(
        icon: Icons.gavel_outlined,
        title: 'A decisão final é humana',
        message: 'Este alerta organiza evidências e não autoriza, executa nem recomenda automaticamente decisões de alto impacto. O responsável deve validar dados e contexto.',
        color: Theme.of(context).colorScheme.error,
      ),
    ],
  );
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Indicador', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 5),
          Text(alert.indicator),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: severityColor(alert.severity).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: severityColor(alert.severity).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evidência numérica',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 5),
                Text(alert.evidence),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissingAlert extends StatelessWidget {
  const _MissingAlert();

  @override
  Widget build(BuildContext context) => const InfoBanner(
    icon: Icons.search_off_rounded,
    title: 'Alerta não encontrado',
    message:
        'O sinal pode ter mudado após a atualização dos dados ou dos limiares.',
  );
}
