import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/brand/brand.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../expenses/forms/forms.dart';
import '../login/session_controller.dart';
import 'usage_change_card.dart';
import 'usage_history_controller.dart';

/// Pantalla HISTORIAL DE USOS: lista todos los usos (de ambos usuarios) y
/// permite añadir usos pasados, editarlos y eliminarlos. Los cambios
/// desincronizados del odómetro requieren la aprobación del otro usuario.
class UsageHistoryScreen extends ConsumerWidget {
  const UsageHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usagesAsync = ref.watch(usageHistoryControllerProvider);
    final me = ref.watch(currentUserProvider);
    final controller = ref.read(usageHistoryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTORIAL DE USOS'),
        actions: [
          IconButton(
            tooltip: 'Añadir uso',
            icon: const Icon(Icons.add),
            onPressed: () => _openCreate(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await controller.refresh();
          await ref.read(usageChangesControllerProvider.notifier).refresh();
        },
        child: AsyncStateView<List<UsageLog>>(
          value: usagesAsync,
          onRetry: controller.refresh,
          errorFallback: 'No se pudo cargar el historial de usos.',
          data: (usages) => _HistoryContent(usages: usages, myUserId: me?.id),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final outcome = await openUsageForm(context);
    if (outcome != null && context.mounted) {
      _snack(
        context,
        outcome == UsageFormOutcome.pendingApproval
            ? 'Cambio enviado para aprobación.'
            : 'Uso registrado.',
      );
    }
  }
}

class _HistoryContent extends ConsumerWidget {
  const _HistoryContent({required this.usages, required this.myUserId});

  final List<UsageLog> usages;
  final int? myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changes =
        ref.watch(usageChangesControllerProvider).asData?.value ?? const [];
    final pending = changes.where((c) => c.status.isPending).toList();
    final pendingUsageIds = {
      for (final c in pending)
        if (c.usageId != null) c.usageId!,
    };
    final usersById = ref.watch(usersByIdProvider).asData?.value ?? const {};

    if (usages.isEmpty && pending.isEmpty) {
      return const RefreshableCenter(
        child: EmptyView(message: 'No hay usos registrados todavía.'),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (pending.isNotEmpty) ...[
          Text('PENDIENTES DE APROBACIÓN', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.md),
          for (final change in pending)
            UsageChangeCard(
              change: change,
              myUserId: myUserId,
              onApprove: () => _act(
                context,
                ref,
                () => ref
                    .read(usageChangesControllerProvider.notifier)
                    .approve(change.id),
                'Cambio aprobado.',
              ),
              onReject: () => _act(
                context,
                ref,
                () => ref
                    .read(usageChangesControllerProvider.notifier)
                    .reject(change.id),
                'Cambio rechazado.',
              ),
              onCancel: () => _act(
                context,
                ref,
                () => ref
                    .read(usageChangesControllerProvider.notifier)
                    .cancel(change.id),
                'Cambio cancelado.',
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text('TODOS LOS USOS', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        if (usages.isEmpty)
          Text(
            'Sin usos registrados.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          )
        else
          for (final usage in usages)
            _UsageTile(
              usage: usage,
              owner: usersById[usage.userId],
              hasPendingChange: pendingUsageIds.contains(usage.id),
            ),
      ],
    );
  }
}

class _UsageTile extends ConsumerWidget {
  const _UsageTile({
    required this.usage,
    required this.owner,
    required this.hasPendingChange,
  });

  final UsageLog usage;
  final User? owner;
  final bool hasPendingChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color =
        colorFromHex(owner?.color) ??
        personColor(owner?.profile ?? 'user1');
    final date = DateTime.tryParse(usage.date);
    final dateLabel = date == null ? usage.date : EsFormat.date(date);
    final typeLabel = usage.type.isShared ? 'Compartido' : 'Individual';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlowCard(
        accentColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PersonAvatar(
                  name: owner?.name ?? '?',
                  profile: owner?.profile ?? 'user1',
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    owner?.name ?? '—',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (hasPendingChange) const _PendingTag(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${EsFormat.km(usage.startKm)} → ${EsFormat.km(usage.endKm)} km',
              style: AppTypography.mono(size: 16, weight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$dateLabel · $typeLabel · +${EsFormat.km(usage.totalKm)} km',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: hasPendingChange
                      ? null
                      : () => _edit(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('EDITAR'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: hasPendingChange
                      ? null
                      : () => _delete(context, ref),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('ELIMINAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final outcome = await openUsageForm(context, edit: usage);
    if (outcome != null && context.mounted) {
      _snack(context, 'Cambio enviado para aprobación.');
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final name = otherUserName(ref);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('¿Eliminar este uso?'),
        content: Text(
          'La eliminación necesita la aprobación de $name. '
          'El registro seguirá visible hasta que la apruebe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _act(
      context,
      ref,
      () async {
        await ref
            .read(usageChangeServiceProvider)
            .proposeDelete(usageId: usage.id);
        ref.invalidate(usageChangesControllerProvider);
        ref.invalidate(pendingUsageChangesProvider);
      },
      'Cambio enviado para aprobación.',
    );
  }
}

class _PendingTag extends StatelessWidget {
  const _PendingTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: AppColors.warning),
      ),
      child: Text(
        'PENDIENTE',
        style: AppTypography.hudLabel(color: AppColors.warning)
            .copyWith(fontSize: 9),
      ),
    );
  }
}

Future<void> _act(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
  String okMessage,
) async {
  try {
    await action();
    if (context.mounted) _snack(context, okMessage);
  } on ApiException catch (e) {
    if (context.mounted) _snack(context, e.message);
  } catch (_) {
    if (context.mounted) _snack(context, 'No se pudo completar la acción.');
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
