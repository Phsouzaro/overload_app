import 'package:flutter/material.dart';

import '../../../core/progression/progression_enums.dart';

typedef SetDetails = ({int? rir, double? rpe, ExecutionQuality? quality});

/// Escala de RPE usada no treino de força (6 a 10, passos de 0,5).
const rpeScale = [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];

/// "8", "8,5": formato curto de um RPE.
String formatRpe(double rpe) => rpe == rpe.roundToDouble()
    ? rpe.toStringAsFixed(0)
    : rpe.toStringAsFixed(1).replaceAll('.', ',');

/// Folha para registrar a qualidade da execução e, quando pedidos, o RIR e o
/// RPE de uma série. Os valores não pedidos são devolvidos sem mudança.
/// Retorna `null` se o usuário cancelar.
Future<SetDetails?> showSetDetailsSheet(
  BuildContext context, {
  required int? rir,
  required ExecutionQuality? quality,
  required bool askRir,
  double? rpe,
  bool askRpe = false,
}) {
  return showModalBottomSheet<SetDetails>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SetDetailsSheet(
      rir: rir,
      rpe: rpe,
      quality: quality,
      askRir: askRir,
      askRpe: askRpe,
    ),
  );
}

class _SetDetailsSheet extends StatefulWidget {
  final int? rir;
  final double? rpe;
  final ExecutionQuality? quality;
  final bool askRir;
  final bool askRpe;

  const _SetDetailsSheet({
    required this.rir,
    required this.rpe,
    required this.quality,
    required this.askRir,
    required this.askRpe,
  });

  @override
  State<_SetDetailsSheet> createState() => _SetDetailsSheetState();
}

class _SetDetailsSheetState extends State<_SetDetailsSheet> {
  late int? _rir = widget.rir;
  late double? _rpe = widget.rpe;
  late ExecutionQuality? _quality = widget.quality;

  static String _qualityLabel(ExecutionQuality? q) => switch (q) {
    null => 'Não marcada',
    ExecutionQuality.valid => 'Válida',
    ExecutionQuality.technicalFailure => 'Falha técnica',
    ExecutionQuality.invalid => 'Inválida',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;
    Widget hint(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: textTheme.bodySmall?.copyWith(color: outline)),
    );

    // Só o conteúdo rola; Cancelar/Salvar ficam sempre visíveis no rodapé.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detalhes da série', style: textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Qualidade da execução', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final q in <ExecutionQuality?>[
                      null,
                      ...ExecutionQuality.values,
                    ])
                      ChoiceChip(
                        label: Text(_qualityLabel(q)),
                        selected: _quality == q,
                        onSelected: (_) => setState(() => _quality = q),
                      ),
                  ],
                ),
                hint(
                  'Falha técnica: a execução saiu do padrão. É diferente de falha '
                  'muscular (⚡), quando não sai mais uma repetição com boa técnica. '
                  'Séries com falha técnica ou inválidas não contam para subir a '
                  'carga.',
                ),
                if (widget.askRir) ...[
                  const SizedBox(height: 20),
                  Text(
                    'RIR (repetições em reserva)',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('—'),
                        selected: _rir == null,
                        onSelected: (_) => setState(() => _rir = null),
                      ),
                      for (var v = 0; v <= 5; v++)
                        ChoiceChip(
                          label: Text(v == 5 ? '5+' : '$v'),
                          selected: _rir == v,
                          onSelected: (_) => setState(() => _rir = v),
                        ),
                    ],
                  ),
                  hint(
                    'Quantas repetições ainda conseguiria fazer com boa técnica. '
                    'É uma estimativa sua: 0 = não sairia mais nenhuma.',
                  ),
                ],
                if (widget.askRpe) ...[
                  const SizedBox(height: 20),
                  Text('RPE (esforço percebido)', style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        key: const ValueKey('rpe-none'),
                        label: const Text('—'),
                        selected: _rpe == null,
                        onSelected: (_) => setState(() => _rpe = null),
                      ),
                      for (final v in rpeScale)
                        ChoiceChip(
                          key: ValueKey('rpe-$v'),
                          label: Text(formatRpe(v)),
                          selected: _rpe == v,
                          onSelected: (_) => setState(() => _rpe = v),
                        ),
                    ],
                  ),
                  hint(
                    'Quão pesada foi a série, de 6 (leve) a 10 (esforço máximo). '
                    'É uma percepção sua, não uma medida exata.',
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop<SetDetails>(context, (
                  rir: widget.askRir ? _rir : widget.rir,
                  rpe: widget.askRpe ? _rpe : widget.rpe,
                  quality: _quality,
                )),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
