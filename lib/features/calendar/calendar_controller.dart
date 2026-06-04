import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Mes mostrado en el calendario (Fase F5). Guarda el **primer día del mes**
/// para navegar entre meses sin perder la alternancia (es continua y la
/// calcula el backend).
class CalendarMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() => state = DateTime(state.year, state.month + 1);

  void goToCurrentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}

final calendarMonthProvider =
    NotifierProvider<CalendarMonthController, DateTime>(
      CalendarMonthController.new,
    );

/// Días del mes (`YYYY-MM`) con su prioridad y marca de handover.
/// `GET /api/calendar?month=`.
final calendarDaysProvider = FutureProvider.autoDispose
    .family<List<CalendarDay>, String>(
      (ref, month) => ref.watch(priorityServiceProvider).calendar(month),
    );
