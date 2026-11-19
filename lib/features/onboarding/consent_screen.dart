import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../providers/app_providers.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _saving = false;

  Future<void> _complete(bool optionalDiagnostics) async {
    setState(() => _saving = true);
    await ref
        .read(consentProvider.notifier)
        .complete(optionalDiagnostics: optionalDiagnostics);
    if (mounted) context.go('/overview');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.teal, AppColors.tealLight],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.hub_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bem-vindo ao\nTerritório Vivo',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Inteligência territorial transparente para apoiar — nunca substituir — decisões humanas.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _ConsentItem(
                        icon: Icons.storage_outlined,
                        title: 'Dados essenciais',
                        body: 'Limiar de alertas, tema, consentimento e cache climático ficam somente neste dispositivo.',
                      ),
                      const SizedBox(height: 16),
                      const _ConsentItem(
                        icon: Icons.shield_outlined,
                        title: 'Sem dados pessoais',
                        body: 'A demonstração usa dados agregados, séries sintéticas e previsão pública. Não solicita identificação individual.',
                      ),
                      const SizedBox(height: 16),
                      const _ConsentItem(
                        icon: Icons.analytics_outlined,
                        title: 'Diagnósticos opcionais',
                        body: 'Você pode autorizar diagnósticos anônimos. Nesta versão acadêmica não há telemetria conectada; a preferência é apenas local e pode ser alterada.',
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : () => _complete(true),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Aceitar opcionais e continuar'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _saving ? null : () => _complete(false),
                          child: const Text('Continuar somente com essenciais'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recusar dados opcionais não limita os recursos essenciais.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  const _ConsentItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer
              .withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
      ),
    ],
  );
}
