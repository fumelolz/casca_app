import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:material_ui/material_ui.dart';

const double _titleWidth = 160;
const double _lineWidth = 220;
const double _labelWidth = 130;
const double _amountWidth = 70;
const List<int> _cardRows = [3, 6, 4];

class ShiftDetailSkeleton extends StatelessWidget {
  const ShiftDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando detalle del turno',
      child: SingleChildScrollView(
        padding: pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space4,
          children: [
            const CascaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CascaSpacing.space2,
                children: [
                  CascaSkeleton(
                    width: _titleWidth,
                    height: CascaSpacing.space6,
                  ),
                  CascaSkeleton(width: _lineWidth),
                  CascaSkeleton(width: _lineWidth),
                ],
              ),
            ),
            for (final rows in _cardRows)
              CascaCard(
                child: Column(
                  spacing: CascaSpacing.space4,
                  children: [
                    for (var row = 0; row < rows; row++)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CascaSkeleton(width: _labelWidth),
                          CascaSkeleton(width: _amountWidth),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
