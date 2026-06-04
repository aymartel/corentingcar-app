import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../login/session_controller.dart';
import 'request_form.dart';
import 'requests_controller.dart';

/// Pantalla SOLICITUDES (Fase F8): pendientes recibidas (aceptar/rechazar),
/// enviadas (cancelar) e historial. Avisos solo in-app.
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(requestsControllerProvider);
    final me = ref.watch(currentUserProvider);
    final controller = ref.read(requestsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOLICITUDES'),
        actions: [
          IconButton(
            tooltip: 'Pedir coche',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final ok = await openRequestForm(context);
              if (ok == true && context.mounted) {
                _snack(context, 'Solicitud enviada.');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface,
        onRefresh: controller.refresh,
        child: AsyncStateView<List<UseRequest>>(
          value: async,
          onRetry: controller.refresh,
          errorFallback: 'No se pudieron cargar las solicitudes.',
          data: (requests) =>
              _RequestsList(requests: requests, myUserId: me?.id),
        ),
      ),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  const _RequestsList({required this.requests, required this.myUserId});

  final List<UseRequest> requests;
  final int? myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final received = requests
        .where((r) => r.status.isPending && r.recipientId == myUserId)
        .toList();
    final sent = requests
        .where((r) => r.status.isPending && r.requesterId == myUserId)
        .toList();
    final history = requests.where((r) => !r.status.isPending).toList();

    if (requests.isEmpty) {
      return const RefreshableCenter(
        child: EmptyView(message: 'No hay solicitudes todavía.'),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (received.isNotEmpty) ...[
          Text('PENDIENTES · RECIBIDAS', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.md),
          for (final r in received)
            _RequestCard(
              request: r,
              otherName: _name(r, incoming: true),
              actions: [
                FilledButton(
                  onPressed: () => _act(
                    context,
                    ref,
                    () => ref
                        .read(requestsControllerProvider.notifier)
                        .accept(r.id),
                    'Solicitud aceptada.',
                  ),
                  child: const Text('ACEPTAR'),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => _act(
                    context,
                    ref,
                    () => ref
                        .read(requestsControllerProvider.notifier)
                        .reject(r.id),
                    'Solicitud rechazada.',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  child: const Text('RECHAZAR'),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (sent.isNotEmpty) ...[
          Text('PENDIENTES · ENVIADAS', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.md),
          for (final r in sent)
            _RequestCard(
              request: r,
              otherName: _name(r, incoming: false),
              actions: [
                OutlinedButton(
                  onPressed: () => _act(
                    context,
                    ref,
                    () => ref
                        .read(requestsControllerProvider.notifier)
                        .cancel(r.id),
                    'Solicitud cancelada.',
                  ),
                  child: const Text('CANCELAR'),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text('HISTORIAL', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        if (history.isEmpty)
          Text(
            'Sin solicitudes resueltas.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          )
        else
          for (final r in history)
            _RequestCard(
              request: r,
              otherName: _name(r, incoming: r.recipientId == myUserId),
            ),
      ],
    );
  }

  String _name(UseRequest r, {required bool incoming}) {
    final user = incoming ? r.requester : r.recipient;
    return user?.name ?? '—';
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
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.otherName,
    this.actions = const [],
  });

  final UseRequest request;
  final String otherName;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(request.useDate);
    final dateLabel = date == null ? request.useDate : EsFormat.date(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(dateLabel, style: theme.textTheme.titleMedium),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(otherName, style: theme.textTheme.bodyLarge),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('"${request.message!}"', style: theme.textTheme.bodySmall),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RequestStatus.pending => ('Pendiente', AppColors.warning),
      RequestStatus.accepted => ('Aceptada', AppColors.success),
      RequestStatus.rejected => ('Rechazada', AppColors.danger),
      RequestStatus.cancelled => ('Cancelada', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: color),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.hudLabel(color: color).copyWith(fontSize: 9),
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
