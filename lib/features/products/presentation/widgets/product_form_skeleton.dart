import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 720;
const double _titleWidth = 200;
const double _labelWidth = 96;
const double _photoSize = 144;

class ProductFormSkeleton extends StatelessWidget {
  const ProductFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando producto',
      child: SingleChildScrollView(
        padding: pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: CascaSkeleton(
                    width: _titleWidth,
                    height: CascaSpacing.space6,
                  ),
                ),
                SizedBox(height: CascaSpacing.space5),
                CascaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CascaSkeleton(
                        width: _photoSize,
                        height: _photoSize,
                        borderRadius: CascaRadius.md,
                      ),
                      _FieldSkeleton(),
                      _FieldSkeleton(),
                      _FieldSkeleton(),
                    ],
                  ),
                ),
                SizedBox(height: CascaSpacing.space4),
                CascaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_FieldSkeleton(), _FieldSkeleton()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: CascaSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CascaSkeleton(width: _labelWidth),
          SizedBox(height: CascaSpacing.space2),
          CascaSkeleton(width: double.infinity, height: CascaSpacing.space8),
        ],
      ),
    );
  }
}
