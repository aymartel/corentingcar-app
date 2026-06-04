import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Resumen de kilómetros del año (Fase F6). Los números los calcula el
/// **backend** (`GET /api/mileage`); la app presenta y avisa.
class MileageController extends AsyncNotifier<MileageSummary> {
  @override
  Future<MileageSummary> build() => ref.read(usageServiceProvider).mileage();

  /// Recarga sin parpadeo (pull-to-refresh / reintento).
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(usageServiceProvider).mileage(),
    );
  }
}

final mileageControllerProvider =
    AsyncNotifierProvider<MileageController, MileageSummary>(
      MileageController.new,
    );
