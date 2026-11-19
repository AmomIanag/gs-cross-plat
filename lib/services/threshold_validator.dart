class ThresholdValidator {
  const ThresholdValidator._();

  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
  }) {
    if (value == null || value.trim().isEmpty) return 'Informe um valor.';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Use apenas números.';
    if (parsed < min || parsed > max) {
      return 'Informe um valor entre ${min.toStringAsFixed(0)} e ${max.toStringAsFixed(0)}.';
    }
    return null;
  }
}
