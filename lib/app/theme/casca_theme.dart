import 'package:material_ui/material_ui.dart';

import 'casca_colors.dart';
import 'casca_radius.dart';
import 'casca_spacing.dart';
import 'casca_typography.dart';

abstract final class CascaTheme {
  static ThemeData get light => _build(Brightness.light, CascaColors.light);

  static ThemeData get dark => _build(Brightness.dark, CascaColors.dark);

  static ThemeData _build(Brightness brightness, CascaColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.primary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      error: c.danger,
      onError: c.onDanger,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.border,
    );

    const buttonShape = RoundedRectangleBorder(borderRadius: CascaRadius.sm);
    const buttonSize = Size(0, CascaSpacing.space8);
    const buttonText = TextStyle(
      fontFamily: CascaTypography.fontFamily,
      fontFamilyFallback: CascaTypography.fontFamilyFallback,
      fontSize: CascaFontSize.sm,
      fontWeight: CascaFontWeight.medium,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.surface,
      dividerColor: c.border,
      fontFamily: CascaTypography.fontFamily,
      fontFamilyFallback: CascaTypography.fontFamilyFallback,
      textTheme: CascaTypography.textTheme(
        color: c.text,
        muted: c.textMuted,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: CascaRadius.sm,
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CascaSpacing.space3,
          vertical: CascaSpacing.space3,
        ),
        hintStyle: TextStyle(
          color: c.textSecondary.withValues(alpha: 0.8),
          fontSize: CascaFontSize.sm,
        ),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        border: _inputBorder(c.border),
        enabledBorder: _inputBorder(c.border),
        focusedBorder: _inputBorder(c.primary),
        errorBorder: _inputBorder(c.danger),
        focusedErrorBorder: _inputBorder(c.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: buttonSize,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          minimumSize: buttonSize,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: buttonSize,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: CascaRadius.md,
          side: BorderSide(color: c.border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      extensions: [c],
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: CascaRadius.sm,
      borderSide: BorderSide(color: color),
    );
  }
}

extension CascaThemeContext on BuildContext {
  CascaColors get casca => Theme.of(this).extension<CascaColors>()!;
}

