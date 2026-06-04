import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Logotipo tipográfico de la marca: **CoRentingCar** escrito con la fuente de
/// marca (Rajdhani) y dos tonos (verde JEEP en "Renting"). Se usa donde el
/// arte (foto del coche) necesita acompañarse del nombre.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 30});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = (Theme.of(context).textTheme.displaySmall ?? const TextStyle())
        .copyWith(fontSize: fontSize, letterSpacing: 0.5, height: 1);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Co',
            style: base.copyWith(color: AppColors.textPrimary),
          ),
          TextSpan(
            text: 'Renting',
            style: base.copyWith(color: AppColors.brand),
          ),
          TextSpan(
            text: 'Car',
            style: base.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
