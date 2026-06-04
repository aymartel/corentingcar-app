import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Índice de la pestaña activa del shell (Fase F1).
///
/// **Patrón de estado fijado para toda la app:** Riverpod con `Notifier`
/// (sin `BuildContext`, seguro en compilación y testable). Las fases con datos
/// del backend usarán `AsyncNotifier` + `AsyncValue` (prioridad, km, solicitudes).
class NavigationController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final navigationControllerProvider =
    NotifierProvider<NavigationController, int>(NavigationController.new);
