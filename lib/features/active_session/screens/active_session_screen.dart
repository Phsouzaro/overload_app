import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/session_providers.dart';
import '../widgets/exercise_session_card.dart';
import 'session_summary_screen.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final int templateId;
  final String templateName;

  const ActiveSessionScreen({
    super.key,
    required this.sessionId,
    required this.templateId,
    required this.templateName,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  late final Timer _sessionTimer;
  int _elapsedSeconds = 0;

  Timer? _restTimer;
  int? _restCountdown;
  int _totalRest = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _sessionTimer.cancel();
    _restTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    if (seconds == 0) return;
    _restTimer?.cancel();
    setState(() {
      _restCountdown = seconds;
      _totalRest = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restCountdown! <= 1) {
        timer.cancel();
        setState(() => _restCountdown = null);
      } else {
        setState(() => _restCountdown = _restCountdown! - 1);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restCountdown = null);
  }

  Future<void> _finishSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await ref
        .read(sessionRepositoryProvider)
        .finishSession(widget.sessionId);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          sessionId: widget.sessionId,
          templateName: widget.templateName,
          elapsedSeconds: _elapsedSeconds,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da sessão?'),
        content: const Text(
            'Você pode encerrar a sessão ou sair sem salvar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Continuar treino'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'exit'),
            child: const Text('Sair sem salvar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'finish'),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (result == 'finish' && mounted) {
      await ref
          .read(sessionRepositoryProvider)
          .finishSession(widget.sessionId);
      return true;
    }
    return result == 'exit';
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync =
        ref.watch(sessionExercisesProvider(widget.sessionId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.templateName),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _formatDuration(_elapsedSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ),
          ],
        ),
        body: exercisesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (exercises) => ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 120),
            itemCount: exercises.length,
            itemBuilder: (context, index) => ExerciseSessionCard(
              key: ValueKey(exercises[index].sessionExercise.id),
              item: exercises[index],
              templateId: widget.templateId,
              onSetConfirmed: _startRestTimer,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_restCountdown != null)
                _RestTimerBanner(
                  countdown: _restCountdown!,
                  total: _totalRest,
                  onSkip: _skipRest,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton(
                  onPressed: _finishSession,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Encerrar Sessão'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _RestTimerBanner extends StatelessWidget {
  final int countdown;
  final int total;
  final VoidCallback onSkip;

  const _RestTimerBanner({
    required this.countdown,
    required this.total,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? countdown / total : 0.0;
    final m = countdown ~/ 60;
    final s = countdown % 60;
    final time =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18),
          const SizedBox(width: 8),
          Text('Descanso  $time',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Pular'),
          ),
        ],
      ),
    );
  }
}
