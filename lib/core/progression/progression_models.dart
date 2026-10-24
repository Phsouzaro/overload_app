import 'progression_enums.dart';

/// Uma série registrada, como o motor a enxerga (independente do banco).
class SetRecord {
  /// Carga em kg. Em séries de peso corporal é a carga adicional (colete,
  /// anilha); `null` = sem carga extra.
  final double? weightKg;
  final int? reps;
  final bool isWarmup;

  /// Falha muscular (não conseguiu outra repetição com técnica adequada).
  final bool toFailure;
  final int? rir;
  final double? rpe;

  /// `null` = não registrada.
  final ExecutionQuality? quality;
  final SetRole? role;

  const SetRecord({
    this.weightKg,
    this.reps,
    this.isWarmup = false,
    this.toFailure = false,
    this.rir,
    this.rpe,
    this.quality,
    this.role,
  });
}

/// Um exercício dentro de uma sessão finalizada.
class SessionRecord {
  final int sessionId;
  final DateTime date;

  /// Config de progressão vigente quando a sessão começou (`null` se nenhuma).
  final int? configId;
  final List<SetRecord> sets;

  const SessionRecord({
    required this.sessionId,
    required this.date,
    required this.sets,
    this.configId,
  });
}

enum ExerciseLoadType { weighted, bodyweight }

/// Dados do exercício necessários para decidir e arredondar cargas.
class ExerciseContext {
  final int exerciseId;
  final String name;
  final ExerciseLoadType loadType;

  /// Menor salto de carga disponível, em kg (já convertido da unidade do
  /// usuário: 5 lb ≈ 2,268 kg).
  final double incrementKg;

  const ExerciseContext({
    required this.exerciseId,
    required this.name,
    required this.loadType,
    required this.incrementKg,
  });
}

/// Meta planejada para uma série da próxima sessão.
class SetTarget {
  final SetRole role;
  final double? weightKg;
  final int? repsMin;
  final int? repsMax;
  final int? rir;
  final double? rpe;

  const SetTarget({
    this.role = SetRole.work,
    this.weightKg,
    this.repsMin,
    this.repsMax,
    this.rir,
    this.rpe,
  });

  Map<String, Object?> toJson() => {
    'role': role.name,
    if (weightKg != null) 'weightKg': weightKg,
    if (repsMin != null) 'repsMin': repsMin,
    if (repsMax != null) 'repsMax': repsMax,
    if (rir != null) 'rir': rir,
    if (rpe != null) 'rpe': rpe,
  };

  factory SetTarget.fromJson(Map<String, Object?> json) => SetTarget(
    role: SetRole.values.byName(json['role'] as String? ?? 'work'),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    repsMin: json['repsMin'] as int?,
    repsMax: json['repsMax'] as int?,
    rir: json['rir'] as int?,
    rpe: (json['rpe'] as num?)?.toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is SetTarget &&
      other.role == role &&
      other.weightKg == weightKg &&
      other.repsMin == repsMin &&
      other.repsMax == repsMax &&
      other.rir == rir &&
      other.rpe == rpe;

  @override
  int get hashCode => Object.hash(role, weightKg, repsMin, repsMax, rir, rpe);

  @override
  String toString() => 'SetTarget(${toJson()})';
}

/// Um critério avaliado (ex: "todas as séries no topo da faixa").
class Criterion {
  /// Código estável, usado em testes e para traduções futuras.
  final String code;
  final String description;

  const Criterion(this.code, this.description);

  Map<String, Object?> toJson() => {'code': code, 'description': description};

  factory Criterion.fromJson(Map<String, Object?> json) =>
      Criterion(json['code'] as String, json['description'] as String);

  @override
  bool operator ==(Object other) => other is Criterion && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Problema de configuração encontrado por `ProgressionStrategy.validate`.
class ConfigIssue {
  final String field;
  final String message;

  const ConfigIssue(this.field, this.message);

  @override
  String toString() => '$field: $message';
}

/// O que uma estratégia decidiu. Não é persistido pela estratégia: quem grava
/// é o `ProgressionService`, sempre como decisão pendente.
class ProgressionResult {
  final RecommendationStatus status;
  final List<SetTarget> nextTargets;
  final List<Criterion> met;
  final List<Criterion> unmet;
  final String reasonCode;

  /// Justificativa em linguagem natural, exibida ao usuário.
  final String explanation;

  /// Carga de trabalho de referência da última sessão analisada, em kg.
  final double? currentWeightKg;
  final List<int> analyzedSessionIds;

  /// Estado próprio da estratégia (ex: sessões bem-sucedidas seguidas, onda
  /// atual), devolvido no próximo `ProgressionInput.previousState`.
  final Map<String, Object?> state;

  const ProgressionResult({
    required this.status,
    required this.reasonCode,
    required this.explanation,
    this.nextTargets = const [],
    this.met = const [],
    this.unmet = const [],
    this.currentWeightKg,
    this.analyzedSessionIds = const [],
    this.state = const {},
  });
}
