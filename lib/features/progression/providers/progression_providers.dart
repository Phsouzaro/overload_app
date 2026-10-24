import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/repositories/progression_repository.dart';
import '../../../core/services/progression_service.dart';

final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  return ProgressionRepository(ref.watch(databaseProvider));
});

final progressionServiceProvider = Provider<ProgressionService>((ref) {
  return ProgressionService(ref.watch(databaseProvider));
});
