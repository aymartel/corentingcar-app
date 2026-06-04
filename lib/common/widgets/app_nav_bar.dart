import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'brand/brand.dart';

/// Descriptor de una pestaña del shell.
class NavTab {
  const NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Etiqueta en español (Hoy, Calendario, Kilómetros, Gastos).
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Barra de navegación inferior de marca (Fase F1 · F0).
///
/// Estilo dark: fondo `surface`, borde superior hairline; el **item activo**
/// usa la **parrilla de 7 ranuras** (`GrilleBars`) como indicador con glow
/// verde, icono y etiqueta en `brand`. Los inactivos van en `textMuted`.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      tab: tabs[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.textMuted;
    return InkResponse(
      onTap: onTap,
      radius: 48,
      highlightColor: AppColors.brand.withValues(alpha: 0.08),
      splashColor: AppColors.brand.withValues(alpha: 0.12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicador de parrilla (solo en el item activo).
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: selected ? 1 : 0,
            child: const GrilleBars(
              height: 6,
              barWidth: 2.5,
              gap: 2,
              barCount: 7,
            ),
          ),
          const SizedBox(height: 8),
          Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            tab.label.toUpperCase(),
            style: AppTypography.hudLabel(color: color).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
