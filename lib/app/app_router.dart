import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/alert_detail_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/dashboards/climate_dashboard_screen.dart';
import '../features/dashboards/energy_dashboard_screen.dart';
import '../features/dashboards/water_dashboard_screen.dart';
import '../features/onboarding/consent_screen.dart';
import '../features/overview/overview_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final consent = ref.watch(consentProvider);
  return GoRouter(
    initialLocation: '/overview',
    redirect: (context, state) {
      final onConsent = state.matchedLocation == '/consent';
      if (!consent.completed && !onConsent) return '/consent';
      if (consent.completed && onConsent) return '/overview';
      return null;
    },
    routes: [
      GoRoute(
        path: '/consent',
        name: 'consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/overview',
            name: 'overview',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/water',
            name: 'water',
            builder: (context, state) => const WaterDashboardScreen(),
          ),
          GoRoute(
            path: '/energy',
            name: 'energy',
            builder: (context, state) => const EnergyDashboardScreen(),
          ),
          GoRoute(
            path: '/climate',
            name: 'climate',
            builder: (context, state) => const ClimateDashboardScreen(),
          ),
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            builder: (context, state) => const AlertsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'alert-detail',
                builder: (context, state) =>
                    AlertDetailScreen(alertId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
