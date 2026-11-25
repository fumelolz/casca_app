import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double _previewAspectRatio = 4 / 3;
const double _selectedBorderWidth = 2;

class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
    super.key,
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema $label',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(CascaSpacing.space2),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: CascaRadius.md,
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? _selectedBorderWidth : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: CascaRadius.sm,
                  child: AspectRatio(
                    aspectRatio: _previewAspectRatio,
                    child: switch (mode) {
                      ThemeMode.light => const _Preview(CascaColors.light),
                      ThemeMode.dark => const _Preview(CascaColors.dark),
                      ThemeMode.system => const Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _Preview(CascaColors.light)),
                          Expanded(child: _Preview(CascaColors.dark)),
                        ],
                      ),
                    },
                  ),
                ),
                const SizedBox(height: CascaSpacing.space2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      CascaIcon(
                        CascaIcons.circleCheck,
                        size: CascaFontSize.md,
                        color: colors.primary,
                        filled: true,
                      ),
                      const SizedBox(width: CascaSpacing.space1),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: selected
                              ? CascaFontWeight.semibold
                              : CascaFontWeight.regular,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.colors);

  final CascaColors colors;

  Widget _bar(Color color, double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: CascaSpacing.space1,
        margin: const EdgeInsets.only(bottom: CascaSpacing.space1),
        decoration: BoxDecoration(color: color, borderRadius: CascaRadius.sm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ColoredBox(
              color: colors.surfaceSidebar,
              child: Padding(
                padding: const EdgeInsets.all(CascaSpacing.space1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(colors.primary, 0.8),
                    _bar(colors.textMuted, 1),
                    _bar(colors.textMuted, 0.7),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(CascaSpacing.space1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(colors.text, 0.5),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(CascaSpacing.space1),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: CascaRadius.sm,
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _bar(colors.textSecondary, 0.9)),
                          _bar(colors.primary, 0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
