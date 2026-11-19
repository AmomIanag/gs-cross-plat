import 'package:flutter_test/flutter_test.dart';
import 'package:territorio_vivo/services/threshold_validator.dart';

void main() {
  group('ThresholdValidator', () {
    test('aceita número decimal com vírgula dentro da faixa', () {
      expect(
        ThresholdValidator.numberInRange('70,5', min: 10, max: 100),
        isNull,
      );
    });

    test('rejeita campo vazio', () {
      expect(
        ThresholdValidator.numberInRange('', min: 10, max: 100),
        'Informe um valor.',
      );
    });

    test('rejeita texto não numérico', () {
      expect(
        ThresholdValidator.numberInRange('chuva', min: 10, max: 100),
        'Use apenas números.',
      );
    });

    test('rejeita valor fora da faixa', () {
      expect(
        ThresholdValidator.numberInRange('101', min: 10, max: 100),
        contains('entre 10 e 100'),
      );
    });
  });
}
