import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// **Faro redondo** (Fase F0 · §4): avatar circular con anillo luminoso en el
/// color de la persona, evocando los faros de JEEP.
///
/// Muestra siempre la **inicial** del nombre para no depender solo del color
/// (accesibilidad / daltonismo).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    required this.profile,
    this.color,
    this.size = 56,
    this.selected = true,
  });

  /// Nombre visible (de él se toma la inicial). UI en español.
  final String name;

  /// Perfil estable: `'user1'` | `'user2'` (define el color canónico).
  final String profile;

  /// Color explícito (p.ej. `users.color` del backend). Si es null usa
  /// [personColor].
  final Color? color;

  final double size;

  /// Si está "apagado", se atenúa (útil para elegir perfil en login).
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? personColor(profile);
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final ring = selected ? ringColor : AppColors.outlineStrong;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceAlt,
        border: Border.all(color: ring, width: 2),
        boxShadow: selected
            ? AppShadows.glow(ringColor, opacity: 0.35, blur: 18)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypography.odometer(
          size: size * 0.42,
          color: selected ? ringColor : AppColors.textMuted,
        ),
      ),
    );
  }
}
