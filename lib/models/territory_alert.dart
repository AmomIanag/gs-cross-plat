enum AlertCategory { water, energy, climate }

enum AlertSeverity { normal, attention, critical }

enum ConfidenceLevel { high, medium, low }

class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    required this.indicator,
    required this.evidence,
    required this.rule,
    required this.justification,
    required this.confidence,
    required this.confidenceRationale,
    required this.limitations,
    required this.recommendation,
    required this.updatedAt,
  });

  final String id;
  final AlertCategory category;
  final AlertSeverity severity;
  final String title;
  final String indicator;
  final String evidence;
  final String rule;
  final String justification;
  final ConfidenceLevel confidence;
  final String confidenceRationale;
  final String limitations;
  final String recommendation;
  final DateTime updatedAt;
}

extension AlertLabels on AlertSeverity {
  String get label => switch (this) {
    AlertSeverity.normal => 'Normal',
    AlertSeverity.attention => 'Atenção',
    AlertSeverity.critical => 'Crítico',
  };
}

extension CategoryLabels on AlertCategory {
  String get label => switch (this) {
    AlertCategory.water => 'Água',
    AlertCategory.energy => 'Energia',
    AlertCategory.climate => 'Clima',
  };
}

extension ConfidenceLabels on ConfidenceLevel {
  String get label => switch (this) {
    ConfidenceLevel.high => 'Alta',
    ConfidenceLevel.medium => 'Média',
    ConfidenceLevel.low => 'Baixa',
  };
}
