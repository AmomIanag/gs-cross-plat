import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:territorio_vivo/app/app.dart';
import 'package:territorio_vivo/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('primeiro acesso exibe consentimento sem bloquear recusa', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const TerritorioVivoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo ao\nTerritório Vivo'), findsOneWidget);
    expect(find.text('Aceitar opcionais e continuar'), findsOneWidget);
    expect(find.text('Continuar somente com essenciais'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
