import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Agenda uma notificação para o fim do descanso, para que o usuário seja
/// avisado mesmo com o app em segundo plano ou com a tela bloqueada.
class RestNotificationService {
  static const _notificationId = 1;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _ready;

  RestNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<bool> _init() async {
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ));
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return true;
    } catch (_) {
      // Plataforma sem suporte (ex: testes): o timer na tela continua valendo.
      return false;
    }
  }

  /// Pede a permissão de notificações logo no início da sessão, e não na
  /// primeira série confirmada.
  Future<void> ensureInitialized() => _ready ??= _init();

  Future<void> schedule(Duration rest, {String? exerciseName}) async {
    if (!await (_ready ??= _init())) return;
    await _plugin.cancel(_notificationId);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;

    await _plugin.zonedSchedule(
      _notificationId,
      'Descanso concluído',
      exerciseName != null
          ? 'Hora da próxima série de $exerciseName'
          : 'Hora da próxima série',
      tz.TZDateTime.now(tz.UTC).add(rest),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer',
          'Timer de descanso',
          channelDescription: 'Aviso quando o descanso entre séries termina',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel() async {
    if (!await (_ready ??= _init())) return;
    await _plugin.cancel(_notificationId);
  }
}
