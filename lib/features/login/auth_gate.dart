import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets/brand/brand.dart';
import '../shell/app_shell.dart';
import 'login_screen.dart';
import 'session_controller.dart';

/// Guardia de arranque (Fase F3): según el estado de la sesión muestra el
/// splash, el login o el shell de 4 pestañas.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    return switch (session) {
      SessionLoading() => const _SplashScreen(),
      SessionUnauthenticated() => const LoginScreen(),
      SessionAuthenticated() => const AppShell(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BrandBackground(
        child: Center(
          child: GrilleBars(animate: true, height: 40, barWidth: 7),
        ),
      ),
    );
  }
}
