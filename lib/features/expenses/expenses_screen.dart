import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/models/models.dart';
import 'expenses_controller.dart';
import 'forms/forms.dart';

/// Pantalla GASTOS (Fase F7): saldo combinado (gasolina + otros gastos, con
/// reparto individual/compartido) y estado del lavado (último y a quién le toca).
/// Punto de entrada a los 4 formularios de registro. `GET /api/expenses`.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expensesControllerProvider);
    final controller = ref.read(expensesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('GASTOS')),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface,
        onRefresh: controller.refresh,
        child: AsyncStateView<ExpensesSummary>(
          value: async,
          onRetry: controller.refresh,
          errorFallback: 'No se pudieron cargar los gastos.',
          data: (summary) => _ExpensesContent(summary: summary),
        ),
      ),
    );
  }
}

class _ExpensesContent extends StatelessWidget {
  const _ExpensesContent({required this.summary});

  final ExpensesSummary summary;

  @override
  Widget build(BuildContext context) {
    final fuel = summary.fuel;
    final other = summary.other;
    final wash = summary.wash;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _ActionsRow(),
        const SizedBox(height: AppSpacing.xl),
        _BalanceCard(balance: summary.balance),
        const SizedBox(height: AppSpacing.xl),
        Text('GASOLINA', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        if (fuel.list.isEmpty)
          _EmptyNote(text: 'Aún no hay repostajes.')
        else
          for (final entry in fuel.list) _FuelHistoryTile(entry: entry),
        const SizedBox(height: AppSpacing.xl),
        Text('OTROS', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        if (other.list.isEmpty)
          _EmptyNote(text: 'Aún no hay otros gastos.')
        else
          for (final entry in other.list) _OtherHistoryTile(entry: entry),
        const SizedBox(height: AppSpacing.xl),
        Text('LAVADO', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        _WashCard(wash: wash),
        if (wash.history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          for (final entry in wash.history) _WashHistoryTile(entry: entry),
        ],
      ],
    );
  }
}

class _ActionsRow extends ConsumerWidget {
  const _ActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.speed_outlined,
                label: 'Uso',
                onTap: () => handleUsageForm(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionTile(
                icon: Icons.local_gas_station_outlined,
                label: 'Gasolina',
                onTap: () =>
                    _handle(context, openFuelForm, 'Gasolina registrada.'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.local_car_wash_outlined,
                label: 'Lavado',
                onTap: () =>
                    _handle(context, openWashForm, 'Lavado registrado.'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionTile(
                icon: Icons.receipt_long_outlined,
                label: 'Otro',
                onTap: () => _handle(
                  context,
                  openOtherExpenseForm,
                  'Gasto registrado.',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    Future<bool?> Function(BuildContext) opener,
    String successMessage,
  ) async {
    final ok = await opener(context);
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brand, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label.toUpperCase(),
            style: AppTypography.hudLabel(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final ExpenseBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (balance.settled || balance.amountEur <= 0) {
      return GlowCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: AppSpacing.md),
            Text('Cuentas saldadas', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    final from = balance.fromUser?.name ?? '—';
    final to = balance.toUser?.name ?? '—';

    return GlowCard(
      accentColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SALDO', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$from debe ${EsFormat.euro(balance.amountEur)} a $to',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            EsFormat.euro(balance.amountEur),
            style: AppTypography.odometer(size: 24, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

class _FuelHistoryTile extends StatelessWidget {
  const _FuelHistoryTile({required this.entry});

  final FuelEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = entry.user;
    final color = colorFromHex(user.color) ?? personColor(user.profile);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: theme.textTheme.bodyLarge),
                Text(
                  _dateLabel(entry.log.date),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _TypeChip(type: entry.log.type),
          const SizedBox(width: AppSpacing.md),
          Text(
            EsFormat.euro(entry.log.amountEur),
            style: AppTypography.mono(size: 15, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OtherHistoryTile extends StatelessWidget {
  const _OtherHistoryTile({required this.entry});

  final OtherExpenseEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = entry.user;
    final color = colorFromHex(user.color) ?? personColor(user.profile);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.log.description,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.name} · ${_dateLabel(entry.log.date)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _TypeChip(type: entry.log.type),
          const SizedBox(width: AppSpacing.md),
          Text(
            EsFormat.euro(entry.log.amountEur),
            style: AppTypography.mono(size: 15, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WashCard extends StatelessWidget {
  const _WashCard({required this.wash});

  final WashSection wash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = wash.last;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ÚLTIMO LAVADO', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.xs),
          Text(
            last == null
                ? 'Sin lavados registrados'
                : '${last.user.name} · ${_dateLabel(last.log.date)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppColors.info, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('LE TOCA A', style: AppTypography.hudLabel()),
              const SizedBox(width: AppSpacing.sm),
              Text(wash.nextWashUser.name, style: theme.textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _WashHistoryTile extends StatelessWidget {
  const _WashHistoryTile({required this.entry});

  final WashEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.local_car_wash_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(entry.user.name, style: theme.textTheme.bodyLarge),
          ),
          Text(_dateLabel(entry.log.date), style: theme.textTheme.bodySmall),
          if (entry.log.costEur != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              EsFormat.euro(entry.log.costEur!),
              style: AppTypography.mono(size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final EntryType type;

  @override
  Widget build(BuildContext context) {
    final shared = type.isShared;
    final color = shared ? AppColors.info : AppColors.textSecondary;
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
        shared ? 'COMPARTIDO' : 'INDIVIDUAL',
        style: AppTypography.hudLabel(color: color).copyWith(fontSize: 9),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
    );
  }
}

String _dateLabel(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  return date == null ? isoDate : EsFormat.date(date);
}
