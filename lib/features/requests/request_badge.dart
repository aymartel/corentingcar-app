import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import 'requests_controller.dart';
import 'requests_screen.dart';

/// Icono de solicitudes con **badge de pendientes** (Fase F8): contador
/// `accentAmber` con glow sobre el negro. Avisos solo in-app. Al tocar, abre
/// la pantalla de SOLICITUDES.
class RequestsBadgeButton extends ConsumerWidget {
  const RequestsBadgeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Solicitudes',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RequestsScreen()),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.accentAmber,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(
                  AppColors.accentAmber,
                  opacity: 0.55,
                  blur: 8,
                ),
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
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
