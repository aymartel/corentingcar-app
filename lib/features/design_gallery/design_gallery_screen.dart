import 'package:flutter/material.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/brand/brand.dart';
import '../../common/widgets/glow_card.dart';

/// Pantalla de muestra del sistema de diseño (Fase F0).
///
/// No es una pantalla del producto: demuestra que el tema oscuro de marca
/// JEEP "luce" (negro a los bordes, verde de acento, parrilla de 7 ranuras,
/// faros, marco HUD y números en monoespaciada). F1 sustituye esto por el
/// shell real de 4 pestañas.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CORETINGCAR'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: Center(child: GrilleBars(height: 20, barWidth: 3.5, gap: 3)),
          ),
        ],
      ),
      body: BrandBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: const [
              _Brand(),
              SizedBox(height: AppSpacing.xl),
              _SectionLabel('Hoy'),
              SizedBox(height: AppSpacing.md),
              _PriorityHero(),
              SizedBox(height: AppSpacing.xl),
              _SectionLabel('Acciones'),
              SizedBox(height: AppSpacing.md),
              _ActionGrid(),
              SizedBox(height: AppSpacing.xl),
              _SectionLabel('Kilómetros'),
              SizedBox(height: AppSpacing.md),
              _MileageBar(
                name: 'Andy',
                profile: 'user1',
                used: 6240,
                limit: 7500,
              ),
              SizedBox(height: AppSpacing.md),
              _MileageBar(
                name: 'Dennis',
                profile: 'user2',
                used: 8430,
                limit: 7500,
              ),
              SizedBox(height: AppSpacing.xl),
              _SectionLabel('Personas'),
              SizedBox(height: AppSpacing.md),
              _PeopleRow(),
              SizedBox(height: AppSpacing.xl),
              _SectionLabel('Cargando'),
              SizedBox(height: AppSpacing.md),
              Center(child: GrilleBars(animate: true, height: 36, barWidth: 6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GrilleBars(height: 44, barWidth: 8, gap: 6),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Coche compartido',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Sin discusiones. Hoy decide quien tiene prioridad.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text.toUpperCase(), style: AppTypography.hudLabel()),
        const SizedBox(width: AppSpacing.md),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _PriorityHero extends StatelessWidget {
  const _PriorityHero();

  @override
  Widget build(BuildContext context) {
    final color = personColor('user1');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rlg,
        border: Border.all(color: AppColors.outline),
        boxShadow: AppShadows.glow(color, opacity: 0.16, blur: 28),
      ),
      child: HudFrame(
        color: color,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            const PersonAvatar(name: 'Andy', profile: 'user1', size: 64),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HOY TIENE PRIORIDAD', style: AppTypography.hudLabel()),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Andy',
                    style: Theme.of(
                      context,
                    ).textTheme.displayMedium?.copyWith(color: color),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'En conflicto hoy decide Andy. Si no es tu día y necesitas el coche, pídelo.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.front_hand_outlined, 'Pedir coche'),
      (Icons.speed_outlined, 'Registrar uso'),
      (Icons.local_gas_station_outlined, 'Gasolina'),
      (Icons.local_car_wash_outlined, 'Lavado'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.4,
      children: [
        for (final (icon, label) in items)
          GlowCard(
            onTap: () {},
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.brand, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTypography.hudLabel(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MileageBar extends StatelessWidget {
  const _MileageBar({
    required this.name,
    required this.profile,
    required this.used,
    required this.limit,
  });

  final String name;
  final String profile;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final color = personColor(profile);
    final ratio = used / limit;
    final exceeded = used > limit;
    final nearLimit = !exceeded && ratio >= 0.85;
    final fillColor = exceeded
        ? AppColors.danger
        : nearLimit
        ? AppColors.warning
        : color;

    return GlowCard(
      accentColor: color,
      glow: exceeded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _fmt(used),
                      style: AppTypography.mono(
                        size: 15,
                        weight: FontWeight.w700,
                        color: fillColor,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${_fmt(limit)} km',
                      style: AppTypography.mono(
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.rsm,
            child: Stack(
              children: [
                Container(height: 12, color: AppColors.surfaceAlt),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [fillColor.withValues(alpha: 0.6), fillColor],
                      ),
                      boxShadow: AppShadows.glow(
                        fillColor,
                        opacity: 0.4,
                        blur: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (exceeded) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Exceso: ${_fmt(used - limit)} km (se pagan)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Formato es-ES de miles con punto (en F2/F1 se hará con `intl`).
  static String _fmt(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _PeopleRow extends StatelessWidget {
  const _PeopleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _personChip(context, 'Andy', 'user1'),
        const SizedBox(width: AppSpacing.md),
        _personChip(context, 'Dennis', 'user2'),
        const Spacer(),
        _badge(),
      ],
    );
  }

  Widget _personChip(BuildContext context, String name, String profile) {
    final color = personColor(profile);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonAvatar(name: name, profile: profile, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Text(name, style: AppTypography.hudLabel(color: color)),
        ],
      ),
    );
  }

  Widget _badge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_outlined,
          color: AppColors.textSecondary,
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.accentAmber,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(
                AppColors.accentAmber,
                opacity: 0.5,
                blur: 8,
              ),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Center(
              child: Text(
                '2',
                textAlign: TextAlign.center,
                style: AppTypography.mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.onAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
