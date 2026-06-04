import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'dimens.dart';
import 'typography.dart';

export 'colors.dart';
export 'dimens.dart';
export 'typography.dart';

/// Tema oscuro de marca CoRetingCar (Fase F0).
///
/// **Dark-only**: la app no declara tema claro. Construye un único
/// [ThemeData] a partir de los tokens de [AppColors] y la tipografía de
/// [AppTypography].
abstract final class AppTheme {
  AppTheme._();

  /// Overlay de System UI: negro a los bordes, iconos claros.
  static const SystemUiOverlayStyle systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.brand,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.brandDeep,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accentAmber,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.info,
      onTertiary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceHigh,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.danger,
      onError: AppColors.onAccent,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineStrong,
    );

    final text = AppTypography.textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      textTheme: text,
      primaryColor: AppColors.brand,
      dividerColor: AppColors.outline,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: text.titleLarge?.copyWith(letterSpacing: 1.2),
        shape: const Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.rmd,
          side: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brand.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.hudLabel(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.textMuted,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceAlt,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rmd),
          textStyle: text.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.outlineStrong, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rmd),
          textStyle: text.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: text.labelLarge,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        side: const BorderSide(color: AppColors.outline),
        labelStyle: text.labelMedium!,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: AppColors.surfaceAlt,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.hudLabel(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rmd,
          borderSide: BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rmd,
          borderSide: BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rmd,
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rmd,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rlg),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: text.bodyMedium,
        actionTextColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rmd),
      ),
    );
  }
}
