import 'progression_enums.dart';
import 'progression_models.dart';
import 'progression_rules.dart';
import 'progression_strategy.dart';

/// Sessão mais recente, já verificada e pronta para a regra da estratégia.
class CheckedSession {
  final SessionRecord session;

  /// As primeiras `sets` séries de trabalho (séries extras são ignoradas).
  final List<SetRecord> considered;

  /// Carga comum às séries consideradas, em kg. Em peso corporal, 0 = sem
  /// carga adicional.
  final double load;

  const CheckedSession(this.session, this.considered, this.load);

  String get repsText => considered.map((s) => s.reps ?? 0).join('/');
}

/// Verificações comuns às estratégias baseadas em carga, para não serem
/// reescritas (e divergirem) em cada uma.
abstract final class SessionChecks {
  /// Antes da regra própria da estratégia: incremento definido, histórico,
  /// séries de trabalho, mesma carga em todas as séries e pausa longa.
  ///
  /// Retorna `stop` quando a estratégia deve devolver esse resultado direto;
  /// senão, `session` com a sessão verificada.
  static ({ProgressionResult? stop, CheckedSession? session}) latest(
    ProgressionInput input, {
    required int sets,
    required SetTarget Function(double? weightKg) targetFor,
  }) {
    final ex = input.exercise;

    if (ex.incrementKg <= 0) {
      return (
        stop: const ProgressionResult(
          status: RecommendationStatus.manualReview,
          reasonCode: 'noIncrement',
          explanation:
              'Defina o incremento de carga disponível para este '
              'exercício para receber sugestões.',
          unmet: [
            Criterion('incrementAvailable', 'Incremento de carga definido'),
          ],
        ),
        session: null,
      );
    }
    if (input.history.isEmpty) {
      return (
        stop: const ProgressionResult(
          status: RecommendationStatus.insufficientData,
          reasonCode: 'noHistory',
          explanation: 'Ainda não há sessões registradas deste exercício.',
        ),
        session: null,
      );
    }

    final latest = input.history.first;
    final analyzed = [latest.sessionId];
    final working = ProgressionRules.workingSets(latest);
    if (working.isEmpty) {
      return (
        stop: ProgressionResult(
          status: RecommendationStatus.insufficientData,
          reasonCode: 'noWorkingSets',
          explanation:
              'A última sessão não tem séries de trabalho registradas '
              '(só aquecimento ou séries vazias).',
          analyzedSessionIds: analyzed,
        ),
        session: null,
      );
    }

    final considered = working.take(sets).toList();
    final loads = {for (final s in considered) s.weightKg ?? 0.0};
    if (loads.length > 1) {
      final described = [
        for (final s in considered) ex.formatLoad(s.weightKg ?? 0),
      ];
      return (
        stop: ProgressionResult(
          status: RecommendationStatus.manualReview,
          reasonCode: 'mixedLoads',
          explanation:
              'As séries usaram cargas diferentes '
              '(${described.join(' / ')}). Escolha a carga de trabalho para a '
              'próxima sessão.',
          unmet: const [
            Criterion('sameLoad', 'Mesma carga em todas as séries de trabalho'),
          ],
          analyzedSessionIds: analyzed,
          nextTargets: [for (final s in considered) targetFor(s.weightKg)],
        ),
        session: null,
      );
    }

    final load = loads.single;
    if (ProgressionRules.isLongBreak(input.history, input.now)) {
      final days = ProgressionRules.daysSinceLastSession(
        input.history,
        input.now,
      );
      return (
        stop: ProgressionResult(
          status: RecommendationStatus.manualReview,
          reasonCode: 'longBreak',
          explanation:
              'Faz $days dias desde a última sessão deste exercício. '
              'Retome com a carga anterior (${describeLoad(load, ex)}) ou '
              'menor, conforme se sentir, antes de voltar a progredir.',
          unmet: const [
            Criterion(
              'recentHistory',
              'Sessão recente (até ${ProgressionRules.longBreakDays} dias)',
            ),
          ],
          currentWeightKg: load,
          analyzedSessionIds: analyzed,
          nextTargets: [
            for (var i = 0; i < sets; i++) targetFor(loadOrNull(load, ex)),
          ],
        ),
        session: null,
      );
    }

    return (stop: null, session: CheckedSession(latest, considered, load));
  }

  /// Séries que não comprovam a meta (falha técnica, inválida ou, se exigido,
  /// sem qualidade marcada).
  static List<SetRecord> invalidSets(
    Iterable<SetRecord> sets, {
    required bool requireMarkedValid,
  }) => [
    for (final s in sets)
      if (!ProgressionRules.countsTowardGoal(
        s,
        requireMarkedValid: requireMarkedValid,
      ))
        s,
  ];

  /// Avalia o RIR das [sets] contra [targetRir]. Falha muscular conta como
  /// RIR 0. `missing`: alguma série sem RIR; `ok`: nenhuma abaixo do alvo.
  static ({bool missing, bool ok}) checkRir(
    Iterable<SetRecord> sets,
    int targetRir,
  ) {
    var missing = false;
    var ok = true;
    for (final s in sets) {
      final rir = s.toFailure ? 0 : s.rir;
      if (rir == null) {
        missing = true;
      } else if (rir < targetRir) {
        ok = false;
      }
    }
    return (missing: missing, ok: ok);
  }

  /// Aviso para a justificativa quando séries sem qualidade marcada foram
  /// consideradas válidas.
  static String qualityNote(
    Iterable<SetRecord> sets, {
    required bool requireMarkedValid,
  }) => !requireMarkedValid && ProgressionRules.hasUnrecordedQuality(sets)
      ? ' A qualidade da execução não foi marcada, então as séries foram '
            'consideradas válidas.'
      : '';

  /// Em peso corporal, carga 0 é "sem carga extra" (`null`).
  static double? loadOrNull(double kg, ExerciseContext ex) =>
      ex.loadType == ExerciseLoadType.bodyweight && kg == 0 ? null : kg;

  static String describeLoad(double kg, ExerciseContext ex) {
    if (ex.loadType == ExerciseLoadType.bodyweight) {
      return kg == 0 ? 'peso corporal' : 'peso corporal + ${ex.formatLoad(kg)}';
    }
    return ex.formatLoad(kg);
  }
}
