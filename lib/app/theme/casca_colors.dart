import 'package:material_ui/material_ui.dart';

@immutable
class CascaColors extends ThemeExtension<CascaColors> {
  const CascaColors({
    required this.primary,
    required this.primaryHover,
    required this.primarySoft,
    required this.onPrimary,
    required this.success,
    required this.successSoft,
    required this.onSuccess,
    required this.warning,
    required this.warningSoft,
    required this.onWarning,
    required this.danger,
    required this.dangerSoft,
    required this.onDanger,
    required this.info,
    required this.infoSoft,
    required this.onInfo,
    required this.background,
    required this.backgroundHover,
    required this.surface,
    required this.surfaceSidebar,
    required this.surfaceHover,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color primary;
  final Color primaryHover;
  final Color primarySoft;
  final Color onPrimary;
  final Color success;
  final Color successSoft;
  final Color onSuccess;
  final Color warning;
  final Color warningSoft;
  final Color onWarning;
  final Color danger;
  final Color dangerSoft;
  final Color onDanger;
  final Color info;
  final Color infoSoft;
  final Color onInfo;
  final Color background;
  final Color backgroundHover;
  final Color surface;
  final Color surfaceSidebar;
  final Color surfaceHover;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color textMuted;

  static const light = CascaColors(
    primary: Color(0xFF3B82F6),
    primaryHover: Color(0xFF60A5FA),
    primarySoft: Color(0xFFEFF6FF),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF15803D),
    successSoft: Color(0xFFF0FDF4),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFB45309),
    warningSoft: Color(0xFFFFFBEB),
    onWarning: Color(0xFFFFFFFF),
    danger: Color(0xFFDC2626),
    dangerSoft: Color(0xFFFEF2F2),
    onDanger: Color(0xFFFFFFFF),
    info: Color(0xFF0369A1),
    infoSoft: Color(0xFFEFF6FF),
    onInfo: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    backgroundHover: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceSidebar: Color(0xFFFFFFFF),
    surfaceHover: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    text: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
  );

  static const dark = CascaColors(
    primary: Color(0xFF4A7FD9),
    primaryHover: Color(0xFF6492E0),
    primarySoft: Color(0xFF2A3547),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF5FB985),
    successSoft: Color(0xFF28362E),
    onSuccess: Color(0xFF14201A),
    warning: Color(0xFFD9A85B),
    warningSoft: Color(0xFF3A3326),
    onWarning: Color(0xFF241D0F),
    danger: Color(0xFFE07A7A),
    dangerSoft: Color(0xFF3D2C2C),
    onDanger: Color(0xFF2A1313),
    info: Color(0xFF6B9FDC),
    infoSoft: Color(0xFF2A3547),
    onInfo: Color(0xFF111C2B),
    background: Color(0xFF202124),
    backgroundHover: Color(0xFF2D2E32),
    surface: Color(0xFF292A2E),
    surfaceSidebar: Color(0xFF252629),
    surfaceHover: Color(0xFF34353A),
    border: Color(0xFF3C3D42),
    text: Color(0xFFE8E9EB),
    textSecondary: Color(0xFFB1B3B8),
    textMuted: Color(0xFF85878D),
  );

  @override
  CascaColors copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primarySoft,
    Color? onPrimary,
    Color? success,
    Color? successSoft,
    Color? onSuccess,
    Color? warning,
    Color? warningSoft,
    Color? onWarning,
    Color? danger,
    Color? dangerSoft,
    Color? onDanger,
    Color? info,
    Color? infoSoft,
    Color? onInfo,
    Color? background,
    Color? backgroundHover,
    Color? surface,
    Color? surfaceSidebar,
    Color? surfaceHover,
    Color? border,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return CascaColors(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      onDanger: onDanger ?? this.onDanger,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      onInfo: onInfo ?? this.onInfo,
      background: background ?? this.background,
      backgroundHover: backgroundHover ?? this.backgroundHover,
      surface: surface ?? this.surface,
      surfaceSidebar: surfaceSidebar ?? this.surfaceSidebar,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      border: border ?? this.border,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  CascaColors lerp(ThemeExtension<CascaColors>? other, double t) {
    if (other is! CascaColors) return this;
    return CascaColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundHover: Color.lerp(backgroundHover, other.backgroundHover, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSidebar: Color.lerp(surfaceSidebar, other.surfaceSidebar, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
