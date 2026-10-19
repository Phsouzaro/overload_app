import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/utils/rest_formatter.dart';
import '../../../core/utils/unit_converter.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Unidade de peso ──────────────────────────────────────────
          _SectionTitle('Unidade de Peso'),
          const SizedBox(height: 8),
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(
                value: WeightUnit.kg,
                icon: Icon(Icons.monitor_weight_outlined),
                label: Text('Quilogramas (kg)'),
              ),
              ButtonSegment(
                value: WeightUnit.lbs,
                icon: Icon(Icons.monitor_weight_outlined),
                label: Text('Libras (lbs)'),
              ),
            ],
            selected: {settings.unit},
            onSelectionChanged: (s) => notifier.setUnit(s.first),
          ),
          const SizedBox(height: 4),
          Text(
            settings.unit == WeightUnit.kg
                ? '1 kg = 2.205 lbs'
                : '1 lbs = 0.454 kg',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),

          const SizedBox(height: 32),

          // ── Descanso padrão ──────────────────────────────────────────
          _SectionTitle('Descanso Padrão'),
          const SizedBox(height: 4),
          Text(
            'Valor inicial ao criar um novo exercício',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: settings.defaultRestSeconds.toDouble(),
                  min: 0,
                  max: 300,
                  divisions: 20,
                  label: formatRest(settings.defaultRestSeconds),
                  onChanged: (v) => notifier.setDefaultRest(v.toInt()),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  formatRest(settings.defaultRestSeconds),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Backup ───────────────────────────────────────────────────
          _SectionTitle('Backup'),
          const SizedBox(height: 4),
          Text(
            'Cópia completa dos treinos, sessões, exercícios e pesos. '
            'Guarde o arquivo fora do celular (Drive, e-mail...).',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          const _BackupSection(),
        ],
      ),
    );
  }
}

class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection();

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  bool _busy = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorText(Object e) => e is FormatException ? e.message : '$e';

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await ref.read(backupServiceProvider).shareBackup();
    } catch (e) {
      if (mounted) _snack('Erro ao gerar backup: ${_errorText(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    final service = ref.read(backupServiceProvider);
    final source = File(path);
    try {
      await service.validateBackup(source);
    } catch (e) {
      if (mounted) _snack(_errorText(e));
      return;
    }
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
            'Todos os dados atuais serão substituídos pelos do backup. '
            'Uma cópia dos dados atuais fica guardada no aparelho por '
            'segurança.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await service.restore(source, target: await BackupService.databaseFile());
      // Abre o banco restaurado; providers que dependem dele são recriados.
      ref.invalidate(databaseProvider);
      if (!mounted) return;
      _snack('Backup restaurado');
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      ref.invalidate(databaseProvider);
      if (mounted) _snack('Erro ao restaurar: ${_errorText(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('Exportar backup'),
          subtitle: const Text('Gera um arquivo .sqlite para compartilhar'),
          onTap: _export,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore_outlined),
          title: const Text('Restaurar backup'),
          subtitle: const Text('Substitui os dados atuais por um backup'),
          onTap: _restore,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
