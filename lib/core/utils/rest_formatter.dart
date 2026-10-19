/// Formata um tempo de descanso: "Sem descanso", "45s", "2min", "1min 30s".
String formatRest(int seconds) {
  if (seconds == 0) return 'Sem descanso';
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '${m}min' : '${m}min ${s}s';
}
