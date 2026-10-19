import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/services/rest_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RestNotificationService sem plataforma de notificações', () {
    test('schedule e cancel não lançam erro', () async {
      final service = RestNotificationService();

      await service.ensureInitialized();
      await service.schedule(const Duration(seconds: 90),
          exerciseName: 'Supino');
      await service.cancel();
    });
  });
}
