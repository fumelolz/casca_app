import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:material_ui/material_ui.dart';

enum CascaButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  danger,
  dangerOutlined,
}

enum CascaButtonSize {
  sm(
    height: CascaSpacing.space6,
    horizontal: CascaSpacing.space3,
    vertical: CascaSpacing.space1,
    fontSize: CascaFontSize.xs,
  ),
  md(
    height: CascaSpacing.space8,
    horizontal: CascaSpacing.space4,
    vertical: CascaSpacing.space2,
    fontSize: CascaFontSize.sm,
  ),
  lg(
    height: CascaSpacing.space8 + CascaSpacing.space2,
    horizontal: CascaSpacing.space5,
    vertical: CascaSpacing.space3,
    fontSize: CascaFontSize.md,
  );

  const CascaButtonSize({
    required this.height,
    required this.horizontal,
    required this.vertical,
    required this.fontSize,
  });

  final double height;
  final double horizontal;
  final double vertical;
  final double fontSize;
}

const double _disabledOpacity = 0.6;

class CascaButton extends StatelessWidget {
  const CascaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CascaButtonVariant.primary,
    this.size = CascaButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final CascaButtonVariant variant;
  final CascaButtonSize size;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final palette = _ButtonPalette.of(variant, context.casca);
    final disabled = onPressed == null || loading;

    final button = FilledButton(
      onPressed: disabled ? null : onPressed,
      style: _style(context, palette),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            SizedBox(
              width: size.fontSize,
              height: size.fontSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.foreground.withValues(alpha: _disabledOpacity),
              ),
            ),
            const SizedBox(width: CascaSpacing.space2),
          ],
          Text(label),
        ],
      ),
    );

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  ButtonStyle _style(BuildContext context, _ButtonPalette palette) {
    final textStyle = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontSize: size.fontSize, fontWeight: CascaFontWeight.medium);

    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, size.height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: size.horizontal,
          vertical: size.vertical,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: CascaRadius.sm),
      ),
      textStyle: WidgetStatePropertyAll(textStyle),
      elevation: const WidgetStatePropertyAll(0),
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateColor.transparent,
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => _resolve(states, palette.foreground, palette.foreground),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => _resolve(states, palette.background, palette.hover),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: _resolve(states, palette.border, palette.hoverBorder),
        ),
      ),
    );
  }

  Color _resolve(Set<WidgetState> states, Color normal, Color hover) {
    if (states.contains(WidgetState.disabled)) {
      return normal.withValues(alpha: _disabledOpacity);
    }
    if (states.contains(WidgetState.hovered)) return hover;
    return normal;
  }
}

class _ButtonPalette {
  const _ButtonPalette({
    required this.background,
    required this.hover,
    required this.foreground,
    required this.border,
    required this.hoverBorder,
  });

  final Color background;
  final Color hover;
  final Color foreground;
  final Color border;
  final Color hoverBorder;

  static _ButtonPalette of(CascaButtonVariant variant, CascaColors c) {
    final clear = c.surface.withValues(alpha: 0);

    return switch (variant) {
      CascaButtonVariant.primary => _ButtonPalette(
        background: c.primary,
        hover: c.primaryHover,
        foreground: c.onPrimary,
        border: c.primary,
        hoverBorder: c.primaryHover,
      ),
      CascaButtonVariant.secondary => _ButtonPalette(
        background: c.surfaceHover,
        hover: Color.lerp(c.surfaceHover, c.border, 0.18)!,
        foreground: c.text,
        border: c.border,
        hoverBorder: c.border,
      ),
      CascaButtonVariant.outlined => _ButtonPalette(
        background: clear,
        hover: Color.lerp(c.surface, c.primary, 0.08)!,
        foreground: c.primary,
        border: c.primary,
        hoverBorder: c.primary,
      ),
      CascaButtonVariant.text => _ButtonPalette(
        background: clear,
        hover: c.surfaceHover,
        foreground: c.text,
        border: clear,
        hoverBorder: clear,
      ),
      CascaButtonVariant.danger => _ButtonPalette(
        background: c.danger,
        hover: Color.lerp(c.danger, c.text, 0.12)!,
        foreground: c.onDanger,
        border: c.danger,
        hoverBorder: Color.lerp(c.danger, c.text, 0.12)!,
      ),
      CascaButtonVariant.dangerOutlined => _ButtonPalette(
        background: clear,
        hover: c.danger.withValues(alpha: 0.12),
        foreground: c.danger,
        border: c.danger,
        hoverBorder: c.danger,
      ),
    };
  }
}
