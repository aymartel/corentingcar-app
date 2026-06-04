import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Prioridad de HOY (Fase F4). La calcula el **backend**
/// (`GET /api/priority/today`); la app solo presenta.
class TodayController extends AsyncNotifier<DailyPriority> {
  @override
  Future<DailyPriority> build() => ref.read(priorityServiceProvider).today();

  /// Recarga sin parpadeo (para pull-to-refresh / reintento): conserva el
  /// contenido actual hasta que llega el nuevo valor.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(priorityServiceProvider).today(),
    );
  }
}

final todayControllerProvider =
    AsyncNotifierProvider<TodayController, DailyPriority>(TodayController.new);
