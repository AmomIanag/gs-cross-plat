import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../models/territory_alert.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertSeverity? _severity;
  AlertCategory? _category;

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);
    return PageContainer(
      refreshIndicator: () async {
        await ref.read(weatherProvider.notifier).refresh();
        ref.invalidate(alertsProvider);
      },
      children: [
        const PageHeading(
          eyebrow: 'Monitoramento explicável',
          title: 'Central de alertas',
          subtitle: 'Sinais calculados a partir dos dados disponíveis e dos limiares configurados — sem decisões automáticas.',
        ),
        const SizedBox(height: 22),
        const SectionHeading('Filtros'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todas severidades'),
                selected: _severity == null,
                onSelected: (_) => setState(() => _severity = null),
              ),
              const SizedBox(width: 8),
              for (final severity in AlertSeverity.values) ...[
                ChoiceChip(
                  label: Text(severity.label),
                  selected: _severity == severity,
                  onSelected: (_) => setState(() => _severity = severity),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Todos os temas'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              const SizedBox(width: 8),
              for (final category in AlertCategory.values) ...[
                FilterChip(
                  label: Text(category.label),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        alerts.when(
          loading: () => const LoadingCard(label: 'Avaliando regras…'),
          error: (error, _) => ErrorState(
            message: 'Não foi possível gerar os alertas: $error',
            onRetry: () => ref.invalidate(alertsProvider),
          ),
          data: (items) {
            final filtered = items.where((alert) {
              final matchesSeverity =
                  _severity == null || alert.severity == _severity;
              final matchesCategory =
                  _category == null || alert.category == _category;
              return matchesSeverity && matchesCategory;
            }).toList();
            if (filtered.isEmpty) {
              return _EmptyAlerts(
                onClear: () => setState(() {
                  _severity = null;
                  _category = null;
                }),
              );
            }
            return Column(
              children: [
                for (var index = 0; index < filtered.length; index++) ...[
                  _AlertCard(alert: filtered[index]),
                  if (index < filtered.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const InfoBanner(
          icon: Icons.info_outline_rounded,
          title: 'Sobre a classificação',
          message: 'Normal, atenção e crítico indicam relação com um limiar determinístico. Não representam urgência oficial nem substituem avaliação técnica.',
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Alerta ${alert.title}. Severidade ${alert.severity.label}. Abrir detalhes.',
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/alerts/${alert.id}'),
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
                      color: severityColor(alert.severity)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(alert.category),
                      color: severityColor(alert.severity),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.category.label.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alert.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  StatusPill(severity: alert.severity),
                ],
              ),
              const SizedBox(height: 14),
              Text(alert.evidence),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Referência: ${formatDateTime(alert.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  IconData _categoryIcon(AlertCategory category) => switch (category) {
    AlertCategory.water => Icons.water_drop_outlined,
    AlertCategory.energy => Icons.bolt_outlined,
    AlertCategory.climate => Icons.cloud_outlined,
  };
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum alerta neste filtro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            const Text(
              'Ajuste os filtros para visualizar outros sinais.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    ),
  );
}
