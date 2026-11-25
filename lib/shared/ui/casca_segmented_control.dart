import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:material_ui/material_ui.dart';

const double _segmentHeight = 36;
const double _disabledOpacity = 0.7;

class CascaSegment<T> {
  const CascaSegment({required this.value, required this.label});

  final T value;
  final String label;
}

class CascaSegmentedControl<T> extends StatelessWidget {
  const CascaSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<CascaSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: Container(
        padding: const EdgeInsets.all(CascaSpacing.space1),
        decoration: BoxDecoration(
          color: colors.backgroundHover,
          borderRadius: CascaRadius.md,
        ),
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(child: _segment(context, segment)),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, CascaSegment<T> segment) {
    final colors = context.casca;
    final selected = segment.value == value;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: segment.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged(segment.value) : null,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            height: _segmentHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary
                  : colors.surface.withValues(alpha: 0),
              borderRadius: CascaRadius.sm,
              boxShadow: selected ? CascaShadows.sm : const [],
            ),
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimary : colors.textSecondary,
                fontWeight: selected
                    ? CascaFontWeight.semibold
                    : CascaFontWeight.regular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
