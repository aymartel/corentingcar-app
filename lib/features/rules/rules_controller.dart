import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Reglas del acuerdo (Fase F9), **solo lectura** desde `GET /api/rules`.
/// Para reintentar tras un error: `ref.invalidate(rulesProvider)`.
final rulesProvider = FutureProvider<Rules>(
  (ref) => ref.watch(rulesServiceProvider).getRules(),
);
