import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/brand/brand.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../login/session_controller.dart';
import '../requests/requests_controller.dart';
import 'calendar_controller.dart';

/// Pantalla CALENDARIO (Fase F5): mes con la prioridad alterna coloreada por
/// persona, navegación entre meses y marcas de cesión (handover). Los datos
/// vienen del backend (`GET /api/calendar`); no se recalcula localmente.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final monthStr = EsFormat.apiMonth(month);
    final async = ref.watch(calendarDaysProvider(monthStr));
    final controller = ref.read(calendarMonthProvider.notifier);

    // Días con una solicitud pendiente (la pintamos con un reloj de arena).
    final requests =
        ref.watch(requestsControllerProvider).asData?.value ?? const [];
    final pendingDates = {
      for (final r in requests)
        if (r.status.isPending) r.useDate,
    };

    final content = AsyncStateView<List<CalendarDay>>(
      value: async,
      onRetry: () => ref.invalidate(calendarDaysProvider(monthStr)),
      errorFallback: 'No se pudo cargar el calendario.',
      data: (days) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _MonthGrid(
          month: month,
          byDate: {for (final d in days) d.date: d},
          pendingDates: pendingDates,
          onTapDay: (day) => _showDayDetail(context, day),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('CALENDARIO'),
        actions: [
          IconButton(
            tooltip: 'Mes actual',
            icon: const Icon(Icons.today_outlined),
            onPressed: controller.goToCurrentMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthHeader(
            month: month,
            onPrevious: controller.previous,
            onNext: controller.next,
          ),
          const _WeekdayHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  ref.refresh(calendarDaysProvider(monthStr).future),
              child: content,
            ),
          ),
          const _Legend(),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, CalendarDay day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DayDetailSheet(day: day),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = EsFormat.monthYear(month);
    final capitalized = label.isEmpty
        ? label
        : '${label[0].toUpperCase()}${label.substring(1)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Center(
              child: Text(
                capitalized,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final initial in EsFormat.weekdayInitials)
            Expanded(
              child: Center(
                child: Text(initial, style: AppTypography.hudLabel()),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.byDate,
    required this.pendingDates,
    required this.onTapDay,
  });

  final DateTime month;
  final Map<String, CalendarDay> byDate;
  final Set<String> pendingDates;
  final ValueChanged<CalendarDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = month.weekday - 1; // lunes primero
    final cellCount = leadingBlanks + daysInMonth;
    final now = DateTime.now();
    final todayIso = _iso(now.year, now.month, now.day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
        childAspectRatio: 0.82,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();
        final dayNumber = index - leadingBlanks + 1;
        final iso = _iso(month.year, month.month, dayNumber);
        final day = byDate[iso];
        return _DayCell(
          dayNumber: dayNumber,
          day: day,
          isToday: iso == todayIso,
          isPending: pendingDates.contains(iso),
          onTap: day == null ? null : () => onTapDay(day),
        );
      },
    );
  }

  static String _iso(int year, int month, int day) =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.day,
    required this.isToday,
    required this.isPending,
    required this.onTap,
  });

  final int dayNumber;
  final CalendarDay? day;
  final bool isToday;
  final bool isPending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = day == null
        ? null
        : colorFromHex(day!.priorityUser.color) ??
              personColor(day!.priorityUser.profile);
    final isHandover = day?.isHandover ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.14) ?? AppColors.surface,
          borderRadius: AppRadius.rsm,
          border: Border.all(
            color: isToday ? (color ?? AppColors.brand) : AppColors.outline,
            width: isToday ? 2 : 1,
          ),
          boxShadow: isToday && color != null
              ? AppShadows.glow(color, opacity: 0.3, blur: 12)
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tick superior del color de la persona.
                Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color ?? Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                Text(
                  '$dayNumber',
                  style: AppTypography.mono(
                    size: 14,
                    weight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: color ?? AppColors.textSecondary,
                  ),
                ),
                // Marca de cesión (parrilla) o hueco para alinear.
                SizedBox(
                  height: 5,
                  child: isHandover && color != null
                      ? GrilleBars(
                          color: color,
                          height: 5,
                          barWidth: 1.5,
                          gap: 1.5,
                          barCount: 5,
                          glow: false,
                        )
                      : null,
                ),
              ],
            ),
            // Solicitud pendiente de aprobación: reloj de arena (ámbar).
            if (isPending)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.hourglass_top,
                  size: 12,
                  color: AppColors.accentAmber,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _LegendItem(color: AppColors.user1, label: 'Andy'),
            _LegendItem(color: AppColors.user2, label: 'Dennis'),
            _LegendHandover(),
            _LegendPending(),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.hudLabel()),
      ],
    );
  }
}

class _LegendHandover extends StatelessWidget {
  const _LegendHandover();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GrilleBars(
          color: AppColors.textSecondary,
          height: 10,
          barWidth: 2,
          gap: 1.5,
          barCount: 5,
          glow: false,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Cesión', style: AppTypography.hudLabel()),
      ],
    );
  }
}

class _LegendPending extends StatelessWidget {
  const _LegendPending();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.hourglass_top, size: 14, color: AppColors.accentAmber),
        const SizedBox(width: AppSpacing.sm),
        Text('Pendiente', style: AppTypography.hudLabel()),
      ],
    );
  }
}

/// Detalle de un día (bottom sheet). Además de la prioridad, ofrece **acciones
/// de solicitud** según el contexto: pedir el coche (si no es tu día), cancelar
/// (si ya lo pediste) o aceptar/rechazar (si te lo han pedido a ti).
class _DayDetailSheet extends ConsumerStatefulWidget {
  const _DayDetailSheet({required this.day});

  final CalendarDay day;

  @override
  ConsumerState<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<_DayDetailSheet> {
  bool _busy = false;
  String? _error;

  CalendarDay get day => widget.day;

  /// Ejecuta una acción de solicitud: cierra el sheet y avisa, o muestra error.
  Future<void> _run(Future<void> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(success)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo completar la acción.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = day.priorityUser;
    final color = colorFromHex(user.color) ?? personColor(user.profile);
    final theme = Theme.of(context);
    final date = DateTime.tryParse(day.date);
    final dateLabel = date == null ? day.date : EsFormat.weekday(date);

    final me = ref.watch(currentUserProvider);
    final requests =
        ref.watch(requestsControllerProvider).asData?.value ??
        const <UseRequest>[];
    UseRequest? pending;
    for (final r in requests) {
      if (r.useDate == day.date && r.status.isPending) {
        pending = r;
        break;
      }
    }
    final isMyDay = me != null && user.id == me.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel.toUpperCase(), style: AppTypography.hudLabel()),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                PersonAvatar(
                  name: user.name,
                  profile: user.profile,
                  color: color,
                  size: 48,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRIORIDAD', style: AppTypography.hudLabel()),
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  day.isHandover ? Icons.swap_horiz : Icons.event_available,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  day.isHandover
                      ? _originLabel(day.origin)
                      : 'Prioridad por alternancia',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._actions(theme, me, pending, isMyDay),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Acciones según el contexto (pedir / cancelar / aceptar+rechazar / es tu día).
  List<Widget> _actions(
    ThemeData theme,
    User? me,
    UseRequest? pending,
    bool isMyDay,
  ) {
    final controller = ref.read(requestsControllerProvider.notifier);

    if (pending != null) {
      final req = pending;
      if (req.requesterId == me?.id) {
        return [
          _note('Has pedido este día · pendiente de aprobación.', AppColors.accentAmber),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: _outlined(
              icon: Icons.close,
              label: 'Cancelar solicitud',
              color: AppColors.danger,
              onPressed: () =>
                  _run(() => controller.cancel(req.id), 'Solicitud cancelada.'),
            ),
          ),
        ];
      }
      if (req.recipientId == me?.id) {
        return [
          _note('${req.requester?.name ?? 'El otro'} te ha pedido este día.',
              AppColors.accentAmber),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _outlined(
                  icon: Icons.close,
                  label: 'Rechazar',
                  color: AppColors.danger,
                  onPressed: () => _run(
                    () => controller.reject(req.id),
                    'Solicitud rechazada.',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _primary(
                  icon: Icons.check,
                  label: 'Aceptar',
                  onPressed: () => _run(
                    () => controller.accept(req.id),
                    'Solicitud aceptada.',
                  ),
                ),
              ),
            ],
          ),
        ];
      }
      return [_note('Hay una solicitud pendiente para este día.', AppColors.accentAmber)];
    }

    if (!isMyDay) {
      return [
        SizedBox(
          width: double.infinity,
          child: _primary(
            icon: Icons.front_hand_outlined,
            label: 'Pedir coche',
            onPressed: () => _run(
              () => controller.requestDay(day.date),
              'Solicitud enviada.',
            ),
          ),
        ),
      ];
    }

    return [_note('Es tu día.', AppColors.brand, icon: Icons.verified_outlined)];
  }

  Widget _note(String text, Color color, {IconData icon = Icons.info_outline}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _primary({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      onPressed: _busy ? null : onPressed,
      icon: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onAccent,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _outlined({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  String _originLabel(String? origin) {
    switch (origin) {
      case 'manual':
        return 'Cesión manual';
      case 'request_accepted':
        return 'Solicitud aceptada';
      case 'one_off_change':
        return 'Cambio puntual';
      default:
        return 'Cesión';
    }
  }
}
