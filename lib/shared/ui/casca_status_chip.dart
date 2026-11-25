import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:material_ui/material_ui.dart';

enum CascaChipTone { success, warning, danger, info, neutral }

const double _dotSize = 6;

class CascaStatusChip extends StatelessWidget {
  const CascaStatusChip({
    super.key,
    required this.label,
    this.tone = CascaChipTone.neutral,
  });

  final String label;
  final CascaChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final (background, foreground) = switch (tone) {
      CascaChipTone.success => (colors.successSoft, colors.success),
      CascaChipTone.warning => (colors.warningSoft, colors.warning),
      CascaChipTone.danger => (colors.dangerSoft, colors.danger),
      CascaChipTone.info => (colors.infoSoft, colors.info),
      CascaChipTone.neutral => (colors.backgroundHover, colors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space2,
        vertical: CascaSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CascaSpacing.space6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: CascaSpacing.space1),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: CascaFontWeight.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
