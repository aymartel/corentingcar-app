import 'package:flutter/material.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/models/models.dart';

/// Tarjeta de un cambio de uso (crear/editar/eliminar) pendiente o resuelto.
/// Compartida entre el historial de usos y la pantalla de solicitudes.
///
/// Las acciones se muestran según el rol cuando el cambio sigue `pending`:
/// el recipient ve APROBAR/RECHAZAR; el requester ve CANCELAR.
class UsageChangeCard extends StatelessWidget {
  const UsageChangeCard({
    super.key,
    required this.change,
    required this.myUserId,
    this.onApprove,
    this.onReject,
    this.onCancel,
  });

  final UsageChange change;
  final int? myUserId;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecipient = myUserId != null && myUserId == change.recipientId;
    final isRequester = myUserId != null && myUserId == change.requesterId;
    final pending = change.status.isPending;

    final actions = <Widget>[
      if (pending && isRecipient) ...[
        FilledButton(onPressed: onApprove, child: const Text('APROBAR')),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
          child: const Text('RECHAZAR'),
        ),
      ] else if (pending && isRequester)
        OutlinedButton(onPressed: onCancel, child: const Text('CANCELAR')),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlowCard(
        accentColor: pending ? AppColors.warning : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_kindLabel, style: AppTypography.hudLabel()),
                ),
                _StatusChip(status: change.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Propone: ${change.requester?.name ?? '—'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _body(theme),
            if (change.reason != null && change.reason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('"${change.reason!}"', style: theme.textTheme.bodySmall),
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

  String get _kindLabel => switch (change.kind) {
    UsageChangeKind.create => 'NUEVO USO',
    UsageChangeKind.update => 'EDICIÓN DE USO',
    UsageChangeKind.delete => 'ELIMINACIÓN DE USO',
  };

  Widget _body(ThemeData theme) {
    switch (change.kind) {
      case UsageChangeKind.create:
        final f = change.proposed;
        if (f == null) return const SizedBox.shrink();
        return _FieldsLine(label: 'Nuevo', fields: f);
      case UsageChangeKind.update:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (change.original != null)
              _FieldsLine(
                label: 'Antes',
                fields: change.original!,
                muted: true,
              ),
            if (change.proposed != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _FieldsLine(label: 'Después', fields: change.proposed!),
            ],
          ],
        );
      case UsageChangeKind.delete:
        final f = change.original;
        if (f == null) return const SizedBox.shrink();
        return _FieldsLine(label: 'Eliminar', fields: f, muted: true);
    }
  }
}

/// Una línea `Etiqueta: 480 → 530 km · 4 jun 2026 · Individual`.
class _FieldsLine extends StatelessWidget {
  const _FieldsLine({
    required this.label,
    required this.fields,
    this.muted = false,
  });

  final String label;
  final UsageChangeFields fields;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(fields.date);
    final dateLabel = date == null ? fields.date : EsFormat.date(date);
    final typeLabel = fields.type.isShared ? 'Compartido' : 'Individual';
    final color = muted ? AppColors.textMuted : AppColors.textPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label.toUpperCase(),
            style: AppTypography.hudLabel(color: AppColors.textSecondary)
                .copyWith(fontSize: 10),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${EsFormat.km(fields.startKm)} → ${EsFormat.km(fields.endKm)} km '
                '(${EsFormat.km(fields.totalKm)} km)',
                style: AppTypography.mono(size: 14, color: color),
              ),
              Text(
                '$dateLabel · $typeLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final UsageChangeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      UsageChangeStatus.pending => ('Pendiente', AppColors.warning),
      UsageChangeStatus.approved => ('Aprobado', AppColors.success),
      UsageChangeStatus.rejected => ('Rechazado', AppColors.danger),
      UsageChangeStatus.cancelled => ('Cancelado', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
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
