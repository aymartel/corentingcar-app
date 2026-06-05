import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/brand/brand.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import 'session_controller.dart';

/// Pantalla de LOGIN (Fase F3): elegir perfil (Andy/Dennis) + PIN. **Sin
/// registro**. Estética dark/JEEP (F0). UI en español.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _pin = TextEditingController();
  String? _selectedProfile;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedProfile != null && _pin.text.trim().isNotEmpty && !_submitting;

  Future<void> _submit() async {
    final profile = _selectedProfile;
    final pin = _pin.text.trim();
    if (profile == null || pin.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).login(profile, pin);
      // Éxito: el AuthGate cambia al shell y descarta esta pantalla.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } catch (_) {
      if (mounted) setState(() => _error = 'Ha ocurrido un error inesperado.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyError(ApiException e) {
    if (e.statusCode == 429) {
      return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }
    if (e.statusCode == 401 || e.statusCode == 400) {
      return 'Perfil o PIN incorrectos.';
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/brand/car_logo.png',
                      width: 280,
                      fit: BoxFit.contain,
                    ),
                    // El logo del coche tiene algo de margen inferior: subimos
                    // el wordmark para pegarlo al coche.
                    Transform.translate(
                      offset: const Offset(0, -16),
                      child: const BrandWordmark(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('ELIGE TU PERFIL', style: AppTypography.hudLabel()),
                    const SizedBox(height: AppSpacing.lg),
                    users.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: GrilleBars(animate: true, height: 28),
                      ),
                      error: (e, _) => _UsersError(
                        message: e is ApiException
                            ? e.message
                            : 'No se pudieron cargar los perfiles.',
                        onRetry: () => ref.invalidate(usersProvider),
                      ),
                      data: (list) => _ProfilePicker(
                        users: list,
                        selectedProfile: _selectedProfile,
                        onSelect: (p) => setState(() => _selectedProfile = p),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _PinField(
                      controller: _pin,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _canSubmit ? _submit : null,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onAccent,
                                ),
                              )
                            : const Text('ENTRAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({
    required this.users,
    required this.selectedProfile,
    required this.onSelect,
  });

  final List<User> users;
  final String? selectedProfile;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final user in users)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ProfileOption(
              user: user,
              selected: selectedProfile == user.profile,
              onTap: () => onSelect(user.profile),
            ),
          ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  final User user;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(user.color) ?? personColor(user.profile);
    return InkResponse(
      onTap: onTap,
      radius: 56,
      child: Column(
        children: [
          PersonAvatar(
            name: user.name,
            profile: user.profile,
            color: color,
            size: 72,
            selected: selected,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.name,
            style: AppTypography.hudLabel(
              color: selected ? color : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: TextInputType.number,
      obscureText: true,
      obscuringCharacter: '●',
      textAlign: TextAlign.center,
      maxLength: 8,
      autofillHints: const [AutofillHints.password],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTypography.odometer(size: 26).copyWith(letterSpacing: 8),
      decoration: const InputDecoration(
        labelText: 'PIN',
        hintText: '••••',
        counterText: '',
      ),
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('REINTENTAR'),
        ),
      ],
    );
  }
}
