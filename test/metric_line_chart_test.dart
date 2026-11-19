import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:territorio_vivo/models/metric_point.dart';
import 'package:territorio_vivo/widgets/metric_line_chart.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets(
    'gráfico horário mantém rótulos espaçados e mudança de dia em tela estreita',
    (tester) async {
      final points = [
        for (var index = 0; index < 24; index++)
          MetricPoint(
            date: DateTime(2026, 11, 18, 20).add(Duration(hours: index)),
            value: 21.3 + index * 0.3,
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: MetricLineChart(
                    points: points,
                    color: Colors.teal,
                    xAxisMode: ChartXAxisMode.hourly,
                    semanticLabel: 'Previsão horária de teste',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('18/11\n20h'), findsOneWidget);
      expect(find.text('19/11\n02h'), findsOneWidget);
    },
  );
}
