import 'package:material_ui/material_ui.dart';

abstract final class CascaFontSize {
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class CascaFontWeight {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
}

abstract final class CascaTypography {
  static const String fontFamily = 'Poppins';
  static const List<String> fontFamilyFallback = ['Inter'];

  static TextTheme textTheme({required Color color, required Color muted}) {
    TextStyle style(double size, FontWeight weight, [Color? override]) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        color: override ?? color,
      );
    }

    return TextTheme(
      displaySmall: style(CascaFontSize.xxl, CascaFontWeight.semibold),
      headlineMedium: style(CascaFontSize.xl, CascaFontWeight.semibold),
      titleLarge: style(CascaFontSize.lg, CascaFontWeight.semibold),
      titleMedium: style(CascaFontSize.md, CascaFontWeight.semibold),
      titleSmall: style(CascaFontSize.sm, CascaFontWeight.medium),
      bodyLarge: style(CascaFontSize.md, CascaFontWeight.regular),
      bodyMedium: style(CascaFontSize.sm, CascaFontWeight.regular),
      bodySmall: style(CascaFontSize.xs, CascaFontWeight.regular, muted),
      labelLarge: style(CascaFontSize.sm, CascaFontWeight.medium),
      labelMedium: style(CascaFontSize.xs, CascaFontWeight.medium),
      labelSmall: style(CascaFontSize.xs, CascaFontWeight.regular, muted),
    );
  }
}
