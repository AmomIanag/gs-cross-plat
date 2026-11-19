import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = location.startsWith('/alerts')
        ? 1
        : location.startsWith('/settings')
        ? 2
        : 0;
    final isRoot =
        location == '/overview' ||
        location == '/alerts' ||
        location == '/settings';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isRoot
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hub_outlined, color: Colors.white),
                ),
              )
            : IconButton(
                tooltip: 'Voltar',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/overview'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TERRITÓRIO VIVO',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'São Paulo · inteligência cidadã',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Abrir configurações',
            child: IconButton(
              tooltip: 'Configurações',
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (selected) {
          switch (selected) {
            case 0:
              context.go('/overview');
            case 1:
              context.go('/alerts');
            case 2:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Visão geral',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}
