import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:material_ui/material_ui.dart';

const double _titleWidth = 220;
const double _subtitleWidth = 360;
const double _nameWidth = 160;
const double _detailWidth = 110;
const double _buttonWidth = 140;
const int _rows = 6;
const int _nameFlex = 3;
const int _priceFlex = 2;

class PriceListDetailSkeleton extends StatelessWidget {
  const PriceListDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Semantics(
      label: 'Cargando lista de precios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CascaSpacing.space4,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: CascaSpacing.space2,
                    children: [
                      CascaSkeleton(
                        width: _titleWidth,
                        height: CascaSpacing.space6,
                      ),
                      CascaSkeleton(width: _subtitleWidth),
                    ],
                  ),
                  const CascaSkeleton(
                    width: double.infinity,
                    height: CascaSpacing.space8,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: CascaRadius.md,
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        for (var row = 0; row < _rows; row++)
                          const _SkeletonRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              CascaSpacing.space4,
              CascaSpacing.space3,
              CascaSpacing.space4,
              CascaSpacing.space3 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: const Align(
              alignment: Alignment.centerRight,
              child: CascaSkeleton(
                width: _buttonWidth,
                height: CascaSpacing.space8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(CascaSpacing.space4),
      child: Row(
        spacing: CascaSpacing.space4,
        children: [
          Expanded(
            flex: _nameFlex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CascaSpacing.space2,
              children: [
                CascaSkeleton(width: _nameWidth),
                CascaSkeleton(width: _detailWidth),
              ],
            ),
          ),
          Expanded(
            flex: _priceFlex,
            child: CascaSkeleton(
              width: double.infinity,
              height: CascaSpacing.space8,
            ),
          ),
        ],
      ),
    );
  }
}
