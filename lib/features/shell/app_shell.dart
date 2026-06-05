import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets/app_nav_bar.dart';
import '../calendar/calendar_screen.dart';
import '../expenses/expenses_screen.dart';
import '../mileage/mileage_screen.dart';
import '../car_status/car_status_controller.dart';
import '../requests/requests_controller.dart';
import '../today/today_screen.dart';
import 'navigation_controller.dart';

/// Las 4 pestañas del shell, con etiquetas en español (Fase F1).
const List<NavTab> _tabs = [
  NavTab(label: 'Hoy', icon: Icons.today_outlined, selectedIcon: Icons.today),
  NavTab(
    label: 'Calendario',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  NavTab(
    label: 'Kilómetros',
    icon: Icons.speed_outlined,
    selectedIcon: Icons.speed,
  ),
  NavTab(
    label: 'Gastos',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
  ),
];

/// Shell de navegación principal (Fase F1): `IndexedStack` de las 4 pantallas
/// (conserva el estado de cada pestaña) + barra inferior de marca.
///
/// F8: al volver a primer plano (`onResume`) refresca las solicitudes
/// pendientes (avisos solo in-app, sin push).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(pendingRequestsProvider);
      // F12: refresca el estado real del coche (sin parpadeo) al volver.
      ref.read(carStatusProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navigationControllerProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          TodayScreen(),
          CalendarScreen(),
          MileageScreen(),
          ExpensesScreen(),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        tabs: _tabs,
        currentIndex: index,
        onTap: ref.read(navigationControllerProvider.notifier).select,
      ),
    );
  }
}
