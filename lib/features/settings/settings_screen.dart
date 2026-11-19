import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../services/threshold_validator.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _waterController;
  late final TextEditingController _energyController;
  late final TextEditingController _rainController;
  late ThemeMode _themeMode;
  late bool _optionalDiagnostics;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    final consent = ref.read(consentProvider);
    _waterController = TextEditingController(
      text: settings.waterThreshold.toStringAsFixed(0),
    );
    _energyController = TextEditingController(
      text: settings.energyGrowthThreshold.toStringAsFixed(0),
    );
    _rainController = TextEditingController(
      text: settings.rainProbabilityThreshold.toStringAsFixed(0),
    );
    _themeMode = settings.themeMode;
    _optionalDiagnostics = consent.optionalDiagnostics;
  }

  @override
  void dispose() {
    _waterController.dispose();
    _energyController.dispose();
    _rainController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) =>
      double.parse(controller.text.replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final settings = AppSettings(
      waterThreshold: _parse(_waterController),
      energyGrowthThreshold: _parse(_energyController),
      rainProbabilityThreshold: _parse(_rainController),
      themeMode: _themeMode,
    );
    await ref.read(settingsProvider.notifier).save(settings);
    await ref
        .read(consentProvider.notifier)
        .complete(optionalDiagnostics: _optionalDiagnostics);
    ref.invalidate(alertsProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferências salvas. Alertas recalculados.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      children: [
        const PageHeading(
          eyebrow: 'Preferências locais',
          title: 'Configurações',
          subtitle: 'Ajuste os limiares que alimentam as regras. As alterações são salvas somente neste dispositivo.',
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limiar dos alertas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valores válidos e realistas para esta demonstração.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _waterController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Consumo elevado de água',
                      suffixText: 'L/hab/dia',
                      helperText: 'Faixa permitida: 80 a 400',
                      prefixIcon: Icon(Icons.water_drop_outlined),
                    ),
                    validator: (value) => ThresholdValidator.numberInRange(
                      value,
                      min: 80,
                      max: 400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _energyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Crescimento energético',
                      suffixText: '%',
                      helperText: 'Faixa permitida: 1 a 100',
                      prefixIcon: Icon(Icons.bolt_outlined),
                    ),
                    validator: (value) => ThresholdValidator.numberInRange(
                      value,
                      min: 1,
                      max: 100,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rainController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Probabilidade de precipitação',
                      suffixText: '%',
                      helperText: 'Faixa permitida: 10 a 100',
                      prefixIcon: Icon(Icons.water_drop_outlined),
                    ),
                    validator: (value) => ThresholdValidator.numberInRange(
                      value,
                      min: 10,
                      max: 100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<ThemeMode>(
                    initialValue: _themeMode,
                    decoration: const InputDecoration(
                      labelText: 'Aparência',
                      prefixIcon: Icon(Icons.contrast_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Seguir o sistema'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Tema claro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Tema escuro'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _themeMode = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Diagnósticos anônimos opcionais'),
                    subtitle: const Text(
                      'Não há telemetria conectada nesta versão; a preferência é mantida localmente.',
                    ),
                    value: _optionalDiagnostics,
                    onChanged: (value) =>
                        setState(() => _optionalDiagnostics = value),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Salvando…' : 'Salvar preferências',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading('Dados, privacidade e consentimento'),
        const SizedBox(height: 12),
        const _PolicyCard(
          icon: Icons.dataset_outlined,
          title: 'Fontes',
          body: 'Clima: Open-Meteo, sem chave. Água e energia: arquivos JSON sintéticos, identificados como demonstração acadêmica.',
        ),
        const SizedBox(height: 10),
        const _PolicyCard(
          icon: Icons.lock_outline_rounded,
          title: 'Privacidade',
          body: 'Nenhum nome, documento, localização individual ou identificador pessoal é solicitado. Preferências e cache ficam no armazenamento local do app.',
        ),
        const SizedBox(height: 10),
        const _PolicyCard(
          icon: Icons.accessibility_new_rounded,
          title: 'Acessibilidade',
          body: 'A interface combina texto, ícones e cores, oferece descrições semânticas e usa layouts flexíveis para ampliação de fonte.',
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.restart_alt_rounded,
          title: 'Efeito imediato',
          message: 'Ao salvar, a central e a visão geral recalculam os alertas com os novos limiares.',
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
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
                const SizedBox(height: 5),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
