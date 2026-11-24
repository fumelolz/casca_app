import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: CascaRadius.md,
        boxShadow: CascaShadows.sm,
      ),
      child: CascaIcon(
        CascaIcons.brandBag,
        size: CascaFontSize.md,
        color: colors.onPrimary,
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.markSize = 36, this.showProduct = true});

  final double markSize;
  final bool showProduct;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(width: CascaSpacing.space3),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Casca',
                maxLines: 1,
                style: textTheme.titleLarge?.copyWith(color: colors.text),
              ),
              if (showProduct) ...[
                const SizedBox(width: CascaSpacing.space1),
                Flexible(
                  child: Text(
                    'Tiendas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      fontSize: CascaFontSize.sm,
                      fontWeight: CascaFontWeight.medium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
