import 'package:flutter/material.dart';

import '../../../core/progression/progression_enums.dart';

typedef SetDetails = ({int? rir, ExecutionQuality? quality});

/// Folha para registrar a qualidade da execução e (se [askRir]) o RIR de uma
/// série. Retorna `null` se o usuário cancelar.
Future<SetDetails?> showSetDetailsSheet(
  BuildContext context, {
  required int? rir,
  required ExecutionQuality? quality,
  required bool askRir,
}) {
  return showModalBottomSheet<SetDetails>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _SetDetailsSheet(rir: rir, quality: quality, askRir: askRir),
  );
}

class _SetDetailsSheet extends StatefulWidget {
  final int? rir;
  final ExecutionQuality? quality;
  final bool askRir;

  const _SetDetailsSheet({
    required this.rir,
    required this.quality,
    required this.askRir,
  });

  @override
  State<_SetDetailsSheet> createState() => _SetDetailsSheetState();
}

class _SetDetailsSheetState extends State<_SetDetailsSheet> {
  late int? _rir = widget.rir;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 6),
          Text(
            'Falha técnica: a execução saiu do padrão. É diferente de falha '
            'muscular (⚡), quando não sai mais uma repetição com boa técnica. '
            'Séries com falha técnica ou inválidas não contam para subir a '
            'carga.',
            style: textTheme.bodySmall?.copyWith(color: outline),
          ),
          if (widget.askRir) ...[
            const SizedBox(height: 20),
            Text('RIR (repetições em reserva)', style: textTheme.titleSmall),
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
            const SizedBox(height: 6),
            Text(
              'Quantas repetições ainda conseguiria fazer com boa técnica. '
              'É uma estimativa sua: 0 = não sairia mais nenhuma.',
              style: textTheme.bodySmall?.copyWith(color: outline),
            ),
          ],
          const SizedBox(height: 20),
          Row(
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
                  quality: _quality,
                )),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
